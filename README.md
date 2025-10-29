
This repository contains useful materials for the Quint Cosmoverse workshop "Beyond Thinking Hard"


# Installation

First of all, you'll need to install Quint. You can follow the detailed instructions [here](https://quint-lang.org/docs/getting-started), but, for short:

```sh
npm i @informalsystems/quint -g
```

If using VSCode, you may also want to install this two extensions:
 - [Quint extension](https://marketplace.visualstudio.com/items?itemName=informal.quint-vscode)
 - [Traces Viewer extension](https://marketplace.visualstudio.com/items?itemName=informal.itf-trace-viewer)

# Useful Resources
 - [Quint cheatsheet](https://quint-lang.org/quint-cheatsheet.pdf)
 - [Language Basics](https://quint-lang.org/docs/language-basics)
 - [Tutorials](https://quint-lang.org/docs/lessons/hello)

## Interact with the model in the REPL

Let's use `offer.qnt` as an example model.
To load this file and module in the REPL, execute:

```sh
quint -r offer.qnt::offer
```

Then, you can explore it however you like. Here's an example:

```bluespec
>>> init
true
>>> offers
Set()
>>> ticket_holders
...
```

## Check some properties in the simulator

This section covers a few ways to use `quint run`.

### An interesting scenario

When starting with specifications, it makes sense to define some desirable/possible scenarios to make sure the model can evolve to a point where something interesting happens. To achieve that, we can write an invariant stating "this interesting thing is never true" and then check it. If the model is working as expected, it should find a violation to this invariant, and the violation should be one of my desirable scenarios. Read more on the [docs](https://quint-lang.org/docs/checking-properties#inspecting-interesting-traces-with---invariant):

This is one such property:

```bluespec
val single_visitor_owns_all_tickets = size(ticket_holders.values()) == 1

  val counterexample = not(single_visitor_owns_all_tickets)
```

And this is how we can run it:

```sh
quint run offer.qnt --invariant=counterexample
```

## Safety properties

Now that we see the model is evolving in a desirable way, we can check that nothing bad ever happens. We define two properties that should be true for every single state:

`offer_safety`: If there is an offer from someone, that someone should be the holder of the ticket.
```bluespec
val offer_safety = offers.forall(offer => {
    ticket_holders.get(offer.ticket) == offer.giver
  })
```

`no_tickets_lost`: No tickets should be created or destroyed, there should be always the same amount of tickets as there was on the initial state (which is five in this model).
```bluespec
val no_tickets_lost = tickets.size() == INIT_TICKETS.keys().size()
```

We can run them with:

```sh
quint run offer.qnt --invariant=offer_safety
```

```sh
quint run offer.qnt --invariant=no_tickets_lost
```

The `offer_safety` property is actually violated! Seems like there is a problem with this model, which we can understand better by inspecting the trace given by Quint. You can try to fix it as an exercise (learn more about writing Quint in the [docs](https://quint-lang.org/docs/language-basics)).


## Writing runs and testing

Sometimes, we want to make it explicit that some scenario can happen. For this model, I want to show how it is possible to steal tickets, which should be a very good argument to anyone using this offering protocol to switch to a better one. For that, I write a definition with the `run` qualifier:

```bluespec
  run stealing =
    init
    // Bob offers his ticket to both Eve and Diane
    .then(propose(2, "Bob", "Eve"))
    .then(propose(2, "Bob", "Diane"))
    // Eve accepts the offer
    .then(accept(offers.filter(o => o.taker == "Eve").getOnlyElement()))
    // Diane also accepts the offer
    .then(accept(offers.filter(o => o.taker == "Diane").getOnlyElement()))
    // Expectation: Eve lost the ticket, Diane stole it!
    .expect(not(ticket_holders.values().contains("Eve")))
```

We can test it, ensuring these steps can happen and that my expectation holds, by using `quint test`:

```sh
quint test offer.qnt --match=stealing
```

## Formal verification

What about the `no_tickets_lost` property? The simulator reported `[ok]` as it didn't find any violation, but does it mean that the property holds? Not really - it just means that the simulator couldn't find any issue after 10 thousand attempts. We run it with more samples and/or more steps to increase confidence, but we'll never me 100% sure. For that, we need formal verification. To formally verify the `no_tickets_lost` property, we run:

```sh
quint verify offer.qnt --invariant=no_tickets_lost
```

This will use the Apalache model checker and verify runs of up to 10 steps (by default), which should be more than enough to capture any scenario on this model. You can also use TLC, which is an unbounded model checker, or really any other tools that work with TLA+, as Quint can be transpiled into TLA+ by running:

```sh
quint compile offer.qnt --target=tlaplus
```

More details on the model checkers can be found [here](https://quint-lang.org/docs/model-checkers). There's also work in progress to make integration with TLC as seamless as the one with Apalache (see [this script](https://github.com/informalsystems/quint/blob/main/tlc/check_with_tlc.sh) for now).

# Binding Models and Code
Have a look at the `bank` example. 
[THIS DESCRIPTION WILL BE EXTENDED]

# Want to know more?
 - all these examples (and more) can be found at [quint-sandbox](https://github.com/informalsystems/quint-sandbox/tree/main) repo
 - a list of larger, production Quint models is [here](https://quint-lang.org/docs/use-cases)
 - common Quint expression, useful across different projects, are collected inside [Spells](https://github.com/informalsystems/quint/tree/main/examples/spells) repository