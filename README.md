# Demo for the Quint Launch Party

This is the code for the demo presented at the Quint Launch Party event on April
8th 2025. The model was inspired by a demo Hillel Wayne presents on his blog post titled
[The Business Case for Formal
Methods](https://www.hillelwayne.com/post/business-case-formal-methods/), which
I really like and recommend reading!

# Context

We are launching the Quint rocket into space, and there are limited tickets. Our speakers have tickets for them and a few extra ones, which they can offer to other people. Once a person accepts an offer, they become the holder of that ticket.

This offering strategy is not bullet-proof, and Quint makes it easy to find out why.

# Using this specification

First of all, you'll need to install Quint. You can follow the detailed instructions [here](https://quint-lang.org/docs/getting-started), but, for short:

```sh
npm i @informalsystems/quint -g
```

## Interact with the model in the REPL

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
Map(1 -> "Gabriela", 2 -> "Julian", 3 -> "Giuliano", 4 -> "Gabriela", 5 -> "Gabriela")
>>> propose(4, "Gabriela", "Oshan")
true
>>> offers
Set({ giver: "Gabriela", taker: "Oshan", ticket: 4 })
>>> ticket_holders
Map(1 -> "Gabriela", 2 -> "Julian", 3 -> "Giuliano", 4 -> "Gabriela", 5 -> "Gabriela")
>>> val offer = offers.getOnlyElement()

>>> offer
{ giver: "Gabriela", taker: "Oshan", ticket: 4 }
>>> accept(offer)
true
>>> offers
Set()
>>> ticket_holders.get(4)
"Oshan"
>>>
```

## Check some properties in the simulator

This section covers a few ways to use `quint run`.

### An interesting scenario

I like to start running my specifications with some desirable scenarios and make sure my model can evolve to a point where something interesting happens. To achieve that, I write and invariant stating "this interesting thing is never true" and then check it. If my model is working as I expect, it should find a violation to this invariant, and the violation should be one of my desirable scenarios. Read more on the [docs](https://quint-lang.org/docs/checking-properties#inspecting-interesting-traces-with---invariant):

This is the property I created:

```bluespec
val gabriela_owns_all_tickets = ticket_holders.values() == Set("Gabriela")

val counterexample = not(gabriela_owns_all_tickets)
```

And this is how I can run it:

```sh
quint run offer.qnt --invariant=counterexample
```

## Safety properties

Now that I see that my model is evolving in a desirable way, I want to check that nothing bad ever happens. I define two properties that should be true for every single state:

`offer_safety`: If there is an offer from someone, that someone should be the holder of the ticket.
```bluespec
val offer_safety = offers.forall(offer => {
  ticket_holders.get(offer.ticket) == offer.giver
})
```

`no_tickets_lost`: No tickets should be created or destroyed, there should be always the same amount of tickets as there was on the initial state (which is five in this model).
```bluespec
val no_tickets_lost = tickets.size() == 5
```

I can run them with:

```sh
quint run offer.qnt --invariant=offer_safety
```

```sh
quint run offer.qnt --invariant=no_tickets_lost
```

The `offer_safety` property is actually violated! Seems like there is a problem with this model, which we can understand better by inspecting the trace given by Quint. You can try to fix it as an exercise (learn more about writing Quint in the [docs](https://quint-lang.org/docs/language-basics)).

### Rust backend

As of version `v0.24.0` (released at the launch), you can also run the same simulation using the Rust backend:

```sh
quint run offer.qnt --invariant=offer_safety --backend=rust
```

## Writing runs and testing

Sometimes, we want to make it explicit that some scenario can happen. For this model, I want to show how it is possible to steal tickets, which should be a very good argument to anyone using this offering protocol to switch to a better one. For that, I write a definition with the `run` qualifier:

```bluespec
  run stealing =
    init
    // Julian offers his ticket to both Oshan and Gabriela
    .then(propose(2, "Julian", "Oshan"))
    .then(propose(2, "Julian", "Gabriela"))
    // Oshan accepts the offer
    .then(accept(offers.filter(o => o.taker == "Oshan").getOnlyElement()))
    // Gabriela also accepts the offer
    .then(accept(offers.filter(o => o.taker == "Gabriela").getOnlyElement()))
    // Expectation: Oshan lost the ticket, Gabriela stole it!
    .expect(not(ticket_holders.values().contains("Oshan")))
```

I can test it, ensuring these steps can happen and that my expectation holds, by using `quint test`:

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

