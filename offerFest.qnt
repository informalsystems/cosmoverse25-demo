// -*- mode: Bluespec; -*-

// Inspired by Hillel Wayne's Demo: 
// https://www.hillelwayne.com/post/business-case-formal-methods
// 
// Models a ticket offering system for Steirischer Herbst Festival. 
// Some people have more than one ticket and they can make an offer to others.
// If the offer is accepted, the ticket is transferred from the giver to the taker.
// (We keep the model very simple, so we do not model prices, bidding, etc.)
// 
// The model contains a bug.
module offerFest {
  import basicSpells.* from "lib/basicSpells"
  import consts.* from "consts"
  import utils.* from "utils"

  type TicketId = int
  type Visitor = str
  type Offer = { ticket: TicketId, giver: Visitor, taker: Visitor }

  var offers: Set[Offer]
  var ticket_holders: TicketId -> Visitor

  

  val tickets = ticket_holders.keys()
  val holders = ticket_holders.values()

  // Give a new offer
  // action propose(ticket, giver, taker)

  // Accept an already existing offer
  // action accept(offer)

  // action init

  // Either an existing offer is accepted or a new offer is proposed
  // action step

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
