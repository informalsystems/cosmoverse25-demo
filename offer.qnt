// -*- mode: Bluespec; -*-

// Inspired by Hillel Wayne's Demo: 
// https://www.hillelwayne.com/post/business-case-formal-methods
// 
// Models a ticket offering system for Cosmoverse 
// Some people have more than one ticket and they can make an offer to others.
// If the offer is accepted, the ticket is transferred from the giver to the taker.
// (We keep the model very simple, so we do not model prices, bidding, etc.)
// 
// The model contains a bug.
module offer {
  import basicSpells.* from "lib/basicSpells"
  import consts.* from "consts"

  type TicketId = int
  type Visitor = str
  type Offer = { ticket: TicketId, giver: Visitor, taker: Visitor }

  var offers: Set[Offer]
  var ticket_holders: TicketId -> Visitor

  pure def new_offer(ticket, giver, taker) = {
    { ticket: ticket, giver: giver, taker: taker }
  }

  val tickets = ticket_holders.keys()
  val holders = ticket_holders.values()

  action propose(ticket, giver, taker) = all {
    // require(giver != taker),
    require(ticket_holders.get(ticket) == giver),
    offers' = offers.union(Set(new_offer(ticket, giver, taker))),
    ticket_holders' = ticket_holders,
  } 

  action accept(offer) = all {
    require(offers.contains(offer)),
    offers' = offers.exclude(Set(offer)),
    ticket_holders' = ticket_holders.set(offer.ticket, offer.taker)
  }

  action init = all {
    offers' = Set(),
    ticket_holders' = INIT_TICKETS,
  }

  action step = any {
    // Either one of the existing offers was accepted
    all {
      // We can only accept if there are any offers
      require(offers.size() > 0),
      nondet offer = offers.oneOf()
      accept(offer)
    },

    // Or a new offer is proposed
    nondet ticket = tickets.oneOf()
    nondet giver = holders.oneOf()
    nondet taker = INTERESTED_VISITORS.oneOf()
    propose(ticket, giver, taker)
  }

  /* Finding interesting scenarios */

  val single_visitor_owns_all_tickets = size(ticket_holders.values()) == 1

  val counterexample = not(single_visitor_owns_all_tickets)

  
  /* Properties */
  // If there is an offer, then the giver must own the ticket
  val offer_safety = offers.forall(offer => {
    ticket_holders.get(offer.ticket) == offer.giver
  })

  val no_tickets_lost = tickets.size() == INIT_TICKETS.keys().size()

  /* Runs */

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
}
