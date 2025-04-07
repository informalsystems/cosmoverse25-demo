// Inspired on Hillel Wayne's Demo: 
// https://www.hillelwayne.com/post/business-case-formal-methods
module offer {
  import basicSpells.* from "lib/basicSpells"

  type TicketId = int
  type Passanger = str
  type Offer = { ticket: TicketId, giver: Passanger, taker: Passanger }

  var offers: Set[Offer]
  var ticket_holders: TicketId -> Passanger

  pure def new_offer(ticket, giver, taker) = {
    { ticket: ticket, giver: giver, taker: taker }
  }

  val tickets = ticket_holders.keys()
  val holders = ticket_holders.values()

  action propose(ticket, giver, taker) = all {
    giver != taker,
    ticket_holders.get(ticket) == giver,
    offers' = offers.union(Set(new_offer(ticket, giver, taker))),
    ticket_holders' = ticket_holders,
  } 

  action accept(offer) = all {
    offers.contains(offer),
    offers' = offers.exclude(Set(offer)),
    ticket_holders' = ticket_holders.set(offer.ticket, offer.taker)
  }

  action init = all {
    offers' = Set(),
    ticket_holders' = Map(
      1 -> "Gabriela",
      2 -> "Julian",
      3 -> "Giuliano",
      4 -> "Gabriela",
      5 -> "Gabriela"
    ),
  }

  action step = any {
    all {
      // We can only accept if there are any offers
      offers.size() > 0,
      nondet offer = offers.oneOf()
      accept(offer)
    },
    nondet ticket = tickets.oneOf()
    nondet giver = holders.oneOf()
    nondet taker = Set("Gabriela", "Julian", "Giuliano", "Oshan").oneOf()
    propose(ticket, giver, taker)
  }

  /* Finding interesting scenarios */

  val gabriela_owns_all_tickets = ticket_holders.values() == Set("Gabriela")

  val counterexample = not(gabriela_owns_all_tickets)

  /* Properties */

  val offer_safety = offers.forall(offer => {
    ticket_holders.get(offer.ticket) == offer.giver
  })

  val no_tickets_lost = tickets.size() == 5

  /* Runs */

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
}
