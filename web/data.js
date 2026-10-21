export const data = {
  work: [
    {id:'landing',title:'Landing page',subtitle:'website / design',symbol:'▥',messages:[
      [true,'Make the first screen feel calmer. One idea, one action.'],
      [false,'I removed the competing links and gave the headline more breathing room. The page now opens with a single question: what do you want to make?'],
      [true,'Keep the typography. Can we try a warmer background?'],
      [false,'A warm paper tone works well with the existing type. The primary button stays dark so the next step is easy to find.'],
      [true,'That feels better. Leave it there for now.'],
      [false,'The layout is ready to review. Your place in this conversation will still be here when you come back.']
    ]},
    {id:'checkout',title:'Fix the checkout',subtitle:'storefront / development',symbol:'⌑',messages:[
      [true,'The order summary jumps when I change the quantity.'],
      [false,'The total row is changing height when the loading indicator appears. I can keep that row at a consistent height.'],
      [true,'Yes. Keep the update inline.'],
      [false,'The number can fade between values while the layout stays still. The button remains available during the update.'],
      [true,'And keep the cart if I switch sessions.'],
      [false,'Exactly. Moving through session history should change where you are, without losing what you were doing.']
    ]},
    {id:'weekend',title:'A weekend away',subtitle:'personal / planning',symbol:'☀',messages:[
      [true,'Somewhere quiet. Good food, a long walk, no complicated itinerary.'],
      [false,'Let’s keep the shape of the weekend simple: arrive Friday, leave Saturday open, and take the slow route home on Sunday.'],
      [true,'That’s the energy. Save the details for later.'],
      [false,'You can pick this back up from the same place. Your draft and scroll position stay with this session.']
    ]},
    {id:'gesture',title:'A better way to switch',subtitle:'interaction / prototype',symbol:'↕',messages:[
      [true,'What if switching conversations was just a gesture?'],
      [false,'Three fingers. Up to go back to the conversation you just left. Down to return.'],
      [true,'Like browser history, but for whatever I’m working on.'],
      [false,'Exactly. The conversation moves with your hand. Release to switch, or pull back to stay here.'],
      [true,'And it should work for messages too.'],
      [false,'Try the Chats tab. Same gesture, different context. Everything in this prototype is sample content.']
    ]}
  ],
  chats: [
    {id:'team',title:'Studio',subtitle:'4 people · sample chat',symbol:'S',messages:[[false,'Morning! The new layout is in the shared folder.'],[true,'Just saw it. The simpler version works.'],[false,'Great. Shall we review after lunch?'],[true,'Yes, 2 works for me.'],[false,'Perfect. I’ll bring the other option so we can compare.'],[true,'Let’s keep it to 20 minutes.'],[false,'Deal.']]},
    {id:'alex',title:'Alex',subtitle:'sample conversation',symbol:'A',messages:[[false,'Coffee tomorrow?'],[true,'Yes! Somewhere near the park?'],[false,'The place on the corner has a terrace.'],[true,'Sounds good. Around 10?'],[false,'See you there ☀️']]},
    {id:'dinner',title:'Dinner plans',subtitle:'3 people · sample chat',symbol:'D',messages:[[false,'I booked a table for Friday.'],[true,'Nice. What time?'],[false,'Eight. Plenty of time to walk there.'],[true,'Perfect. I’ll bring the good stories.'],[false,'That’s a promise now.']]},
    {id:'sam',title:'Sam',subtitle:'sample conversation',symbol:'S',messages:[[false,'Did you manage to build that idea?'],[true,'Trying it right now.'],[false,'The three-finger thing?'],[true,'Yes. Back and forward through chats.'],[false,'I want to try it. I keep losing my place between conversations.'],[true,'Exactly the problem.']]}
  ]
};
