import {test} from 'node:test';
import assert from 'node:assert/strict';
import {PreviewDrag, dragSettings, dragOutcome, defaultTouchMode} from '../site/drag.js';
import {ThreeFingerGesture} from '../web/history.js';

test('multitouch phones default to three fingers, with an explicit one-finger fallback',()=>{
  assert.equal(defaultTouchMode(5,true,null),3);
  assert.equal(defaultTouchMode(5,false,null),1);
  assert.equal(defaultTouchMode(0,false,null),1);
  assert.equal(defaultTouchMode(5,true,'1'),1);
  assert.equal(defaultTouchMode(0,false,'3'),3);
});

test('the three-finger gate feeds the web switch, pause and cancellation decisions',()=>{
  for(const action of ['switch','overview','cancel']) {
    let time=0,track,result;
    const touches=(count,y=0)=>Array.from({length:count},(_,id)=>({id,x:100+id*40,y:200+y}));
    const gesture=new ThreeFingerGesture({
      begin:()=>{track=new PreviewDrag(0,time);},
      move:dy=>track.move(dy,time),
      end:(_dy,_velocity,cancelled)=>{result=cancelled?'cancel':dragOutcome(track.sample(time),dragSettings(306,667));},
    });
    gesture.start(touches(1),time);
    gesture.start(touches(2),time=20);
    assert.equal(track,undefined);
    gesture.start(touches(3),time=40);
    gesture.move(touches(3,85),time=340);
    if(action==='cancel') gesture.start(touches(4,85),time=350);
    else gesture.end([],time=action==='overview'?600:350);
    assert.equal(result,action);
  }
});

test('a comfortable swipe switches in both directions at phone and desktop sizes',()=>{
  for(const width of [268,295,330]) {
    const settings=dragSettings(width,width*2048/940);
    for(const direction of [-1,1]) {
      assert.equal(dragOutcome({distance:direction*60,velocity:direction*150,heldFor:0},settings),'switch');
      assert.equal(dragOutcome({distance:direction*25,velocity:direction*700,heldFor:0},settings),'switch');
      assert.equal(dragOutcome({distance:direction*12,velocity:direction*700,heldFor:0},settings),'cancel');
    }
  }
});

test('pausing at the shrunken midpoint opens the stack, ordinary releases switch',()=>{
  const settings=dragSettings(295,643);
  for(const direction of [-1,1]) {
    const sample={distance:direction*85,velocity:0,heldFor:0};
    assert.equal(dragOutcome(sample,settings),'switch');
    assert.equal(dragOutcome({...sample,heldFor:240},settings),'overview');
    assert.equal(dragOutcome({...sample,distance:direction*170,heldFor:240},settings),'switch');
    assert.equal(dragOutcome({...sample,velocity:-direction*300},settings),'cancel');
  }
});

test('a still pointer and small jitter count as a pause without needing another move event',()=>{
  const drag=new PreviewDrag(300,0);
  drag.move(340,100); drag.move(385,200);
  assert.equal(dragOutcome(drag.sample(220),dragSettings(295,643)),'switch');
  drag.move(387,310);
  assert.equal(drag.sample(420).velocity,0);
  assert.equal(dragOutcome(drag.sample(420),dragSettings(295,643)),'overview');
  drag.move(355,440);
  assert.equal(dragOutcome(drag.sample(440),dragSettings(295,643)),'cancel');
});
