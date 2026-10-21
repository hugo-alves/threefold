import {test} from 'node:test';
import assert from 'node:assert/strict';
import {PreviewDrag, dragSettings, dragOutcome} from '../site/drag.js';

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
