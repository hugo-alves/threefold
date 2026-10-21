import { test } from 'node:test';
import assert from 'node:assert/strict';
import { SessionHistory, ThreeFingerGesture, shouldCommit, historyStep, shouldOpenOverview, cardScaleAt } from '../web/history.js';

const points = (count, y = 0, x = 0) => Array.from({length:count}, (_,i) => ({id:i,x:100+i*45+x,y:300+y}));
function harness() {
  const calls = [];
  const gesture = new ThreeFingerGesture({begin:()=>calls.push('begin'),move:y=>calls.push(['move',y]),end:(...args)=>calls.push(['end',...args])});
  return {gesture,calls};
}
test('browser-style history stays stable and a new visit truncates the forward branch', () => {
  const history = new SessionHistory(['A','B','C']);
  history.move(-1); history.move(-1); history.move(-1);
  assert.equal(history.current,'A');
  history.move(1);
  assert.deepEqual(history.entries,['A','B','C']);
  history.visit('D');
  assert.deepEqual(history.entries,['A','B','D']);
  assert.equal(history.destination(1),undefined);
  history.visit('D'); assert.equal(history.entries.length,3);
});
test('only a three-finger chord enters navigation', () => {
  for (const count of [1,2,4]) {
    const {gesture,calls} = harness();
    gesture.start(points(count),0); gesture.move(points(count,-180),200); gesture.end([],220);
    assert.deepEqual(calls,[]);
  }
  const {gesture,calls} = harness();
  gesture.start(points(1),0); gesture.start(points(2),10); gesture.start(points(3),20);
  gesture.move(points(3,-130),220); gesture.end(points(2,-130),240); gesture.end([],260);
  assert.equal(calls[0],'begin');
  assert.deepEqual(calls[1],['move',-130]);
  assert.equal(calls[2][3],false);
  assert.equal(gesture.active,false);
});
test('a fourth finger or horizontal movement cancels', () => {
  for (const action of ['fourth','horizontal']) {
    const {gesture,calls} = harness();
    gesture.start(points(3),0);
    if (action === 'fourth') gesture.start(points(4),40);
    else gesture.move(points(3,5,100),100);
    assert.equal(calls.at(-1)[3],true);
    assert.equal(gesture.active,false);
  }
});
test('distance, flick, short drag, reverse, and stale velocity have distinct outcomes', () => {
  assert.equal(shouldCommit(-120,0,600),true);
  assert.equal(shouldCommit(35,800,600),true);
  assert.equal(shouldCommit(8,1000,600),false);
  assert.equal(shouldCommit(-130,350,600),false);
  assert.equal(shouldCommit(40,0,600),false);
  const {gesture,calls} = harness();
  gesture.start(points(3),0); gesture.move(points(3,-40),30); gesture.end([],500);
  assert.equal(calls.at(-1)[2],0);
});
test('cancellation permits another gesture after all fingers lift', () => {
  const {gesture,calls} = harness();
  gesture.start(points(3),0); gesture.cancel(); gesture.end([],10);
  gesture.start(points(3),50); gesture.move(points(3,140),250); gesture.end([],270);
  assert.equal(calls.filter(c=>c==='begin').length,2);
  assert.equal(calls.at(-1)[3],false);
});
test('spatial direction and overview selection preserve the native history order', () => {
  const history = new SessionHistory(['oldest','middle','newest']);
  history.move(historyStep(120)); assert.equal(history.current,'middle');
  history.move(historyStep(-120)); assert.equal(history.current,'newest');
  history.select(0); history.select(100); assert.equal(history.current,'oldest');
  assert.deepEqual(history.entries,['oldest','middle','newest']);
  assert.equal(historyStep(0),0);
});
test('gentle release opens the stack while a flick or reversal does not', () => {
  assert.equal(shouldOpenOverview(145,50,700),true);
  assert.equal(shouldOpenOverview(-145,-50,700),true);
  assert.equal(shouldOpenOverview(145,900,700),false);
  assert.equal(shouldOpenOverview(145,-300,700),false);
  assert.equal(shouldOpenOverview(20,0,700),false);
  assert.equal(shouldOpenOverview(650,0,700),false);
  assert.equal(cardScaleAt(0,700),1);
  assert.equal(cardScaleAt(145,700),.72);
  assert.equal(cardScaleAt(728,700),1);
});
test('a rejected begin does not capture the gesture', () => {
  const gesture = new ThreeFingerGesture({begin:()=>false});
  assert.equal(gesture.start(points(3),0),false);
  assert.equal(gesture.active,false);
});
