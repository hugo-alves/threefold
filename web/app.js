import { data } from './data.js';
import { SessionHistory, shouldCommit, ThreeFingerGesture } from './history.js';

const stage = document.querySelector('#stage');
const label = document.querySelector('#gesture-label');
const hint = document.querySelector('.gesture-hint');
const back = document.querySelector('#back');
const forward = document.querySelector('#forward');
const position = document.querySelector('#position');
const picker = document.querySelector('#session-picker');
const dialog = document.querySelector('#sessions-dialog');
const histories = Object.fromEntries(Object.entries(data).map(([key, sessions]) => [key, new SessionHistory(sessions.map(s => s.id))]));
const cards = new Map();
const scrollPositions = new Map();
let mode = 'work';
let active, preview, direction = 0, busy = false, currentDy = 0, mouse = null;
const history = () => histories[mode];
const titleFor = id => data[mode].find(s => s.id === id).title;
const element = (tag, cls, text) => {
  const el = document.createElement(tag);
  if (cls) el.className = cls;
  if (text !== undefined) el.textContent = text;
  return el;
};

function message(outgoing, copy, chat, index = 0) {
  const row = element('div', `message ${outgoing ? 'outgoing' : 'incoming'}`);
  if (!outgoing && !chat) row.append(element('span', 'speaker', 'Assistant'));
  row.append(element('span', 'copy', copy));
  if (chat) row.append(element('span', 'message-time', `10:${String(22 + index).padStart(2, '0')}${outgoing ? '  ✓✓' : ''}`));
  return row;
}
function makeCard(id) {
  if (cards.has(id)) return cards.get(id);
  const session = data[mode].find(s => s.id === id);
  const chat = mode === 'chats';
  const card = element('section', `session ${chat ? 'chats' : 'work'}`);
  card.dataset.session = id;
  card.setAttribute('aria-label', session.title);
  const header = element('header', 'session-header');
  const heading = element('div');
  heading.append(element('h2', 'session-title', session.title), element('p', 'session-subtitle', session.subtitle));
  const symbol = element('div', 'session-symbol', session.symbol);
  symbol.setAttribute('aria-hidden', 'true');
  header.append(symbol, heading);
  const conversation = element('div', 'conversation');
  conversation.setAttribute('role', 'region');
  conversation.setAttribute('aria-label', `${session.title} messages`);
  conversation.append(element('div', 'date-label', 'TODAY · SAMPLE CONVERSATION'));
  session.messages.forEach(([outgoing, copy], index) => conversation.append(message(outgoing, copy, chat, index)));
  const composer = element('form', 'composer');
  const input = element('input');
  input.placeholder = chat ? 'Message…' : 'Keep the thought going…';
  input.setAttribute('aria-label', `Draft for ${session.title}`);
  input.autocomplete = 'off';
  const send = element('button', '', '↑');
  send.setAttribute('aria-label', 'Add sample message');
  composer.append(input, send);
  composer.addEventListener('submit', event => {
    event.preventDefault();
    const value = input.value.trim();
    if (!value) return;
    conversation.append(message(true, value, chat));
    input.value = '';
    conversation.scrollTop = conversation.scrollHeight;
  });
  card.append(header, conversation, composer);
  cards.set(id, card);
  return card;
}
function saveScroll(card) {
  scrollPositions.set(card.dataset.session, card.querySelector('.conversation').scrollTop);
}
function mount(card) {
  stage.append(card);
  const scroll = card.querySelector('.conversation');
  scroll.scrollTop = scrollPositions.get(card.dataset.session) ?? scroll.scrollHeight;
}
function render() {
  if (active) { saveScroll(active); active.remove(); }
  active = makeCard(history().current);
  active.style.transform = '';
  active.inert = false;
  active.removeAttribute('aria-hidden');
  mount(active);
  updateControls();
}
function updateControls() {
  back.disabled = busy || !history().destination(-1);
  forward.disabled = busy || !history().destination(1);
  picker.disabled = busy;
  document.querySelectorAll('[data-mode]').forEach(button => {
    button.disabled = busy;
    button.setAttribute('aria-pressed', button.dataset.mode === mode);
  });
  position.replaceChildren(...history().entries.map((id, i) => element('i', i === history().cursor ? 'current' : '')));
  position.setAttribute('aria-label', `Session ${history().cursor + 1} of ${history().entries.length}`);
  label.textContent = '3 fingers · down for older · up for newer';
  hint.classList.remove('active');
  stage.dataset.current = history().current;
  stage.dataset.cursor = history().cursor;
}
function begin() {
  if (busy) return false;
  busy = true;
  direction = 0;
  currentDy = 0;
  saveScroll(active);
  active.querySelector('.conversation').style.overflowY = 'hidden';
  updateControls();
  return true;
}
function move(dy) {
  if (!busy) return;
  currentDy = dy;
  const nextDirection = dy < 0 ? 1 : -1;
  const height = stage.clientHeight + 12;
  if (nextDirection !== direction) {
    if (preview) preview.remove();
    preview = null;
    direction = nextDirection;
    const nextId = history().destination(direction);
    if (nextId) {
      preview = makeCard(nextId);
      mount(preview);
      preview.inert = true;
      preview.setAttribute('aria-hidden', 'true');
      preview.style.zIndex = '0';
      active.style.zIndex = '1';
    }
  }
  const offset = preview ? Math.max(-height, Math.min(height, dy)) : dy * .18;
  active.style.transform = `translateY(${offset}px)`;
  if (preview) preview.style.transform = `translateY(${offset + direction * height}px)`;
  const ready = preview && Math.abs(dy) >= Math.min(110, stage.clientHeight * .19);
  hint.classList.toggle('active', Boolean(ready));
  label.textContent = preview ? `${ready ? 'Release' : 'Keep moving'} · ${titleFor(history().destination(direction))}` : direction < 0 ? 'Start of history' : 'You’re at the latest session';
}
async function finish(commit) {
  if (!busy) return;
  commit = commit && Boolean(preview);
  const outgoing = active;
  const incoming = preview;
  const travel = stage.clientHeight + 12;
  const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const options = { duration: reduce ? 1 : 280, easing: 'cubic-bezier(.2,.8,.2,1)', fill: 'forwards' };
  const animations = [outgoing.animate([{transform:outgoing.style.transform || 'translateY(0px)'},{transform:`translateY(${commit ? -direction * travel : 0}px)`}], options)];
  if (incoming) animations.push(incoming.animate([{transform:incoming.style.transform},{transform:`translateY(${commit ? 0 : direction * travel}px)`}],options));
  await Promise.all(animations.map(animation => animation.finished.catch(() => {})));
  if (commit) {
    outgoing.querySelector('input').blur();
    history().move(direction);
    outgoing.remove();
    outgoing.inert = true;
    outgoing.setAttribute('aria-hidden', 'true');
    active = incoming;
    active.inert = false;
    active.removeAttribute('aria-hidden');
  } else if (incoming) incoming.remove();
  animations.forEach(animation => animation.cancel());
  outgoing.style.transform = '';
  outgoing.querySelector('.conversation').style.overflowY = '';
  active.style.transform = '';
  preview = null;
  direction = 0;
  busy = false;
  updateControls();
  if (commit) label.textContent = `${titleFor(history().current)} · ${history().cursor + 1} of ${history().entries.length}`;
}
function navigate(value) {
  if (!history().destination(value) || !begin()) return;
  move(-value);
  finish(true);
}
const gesture = new ThreeFingerGesture({
  begin,
  move,
  end: (dy, velocity, cancelled) => finish(!cancelled && shouldCommit(dy, velocity, stage.clientHeight))
});
const points = event => Array.from(event.touches, touch => ({id:touch.identifier, x:touch.clientX, y:touch.clientY}));
stage.addEventListener('touchstart', event => {
  if (busy && !gesture.active) { if (event.cancelable) event.preventDefault(); return; }
  if (gesture.start(points(event), event.timeStamp) && event.cancelable) event.preventDefault();
}, {passive:false});
stage.addEventListener('touchmove', event => {
  if (gesture.move(points(event), event.timeStamp) && event.cancelable) event.preventDefault();
}, {passive:false});
stage.addEventListener('touchend', event => gesture.end(points(event),event.timeStamp));
stage.addEventListener('touchcancel', event => { gesture.cancel(); if (!event.touches.length) gesture.reset(); });
stage.addEventListener('pointerdown', event => {
  if (event.pointerType !== 'mouse' || !event.altKey || !begin()) return;
  event.preventDefault();
  mouse = { y:event.clientY, last:event.clientY, time:event.timeStamp, velocity:0 };
  stage.setPointerCapture(event.pointerId);
});
stage.addEventListener('pointermove', event => {
  if (!mouse) return;
  const dt = event.timeStamp - mouse.time;
  mouse.velocity = (event.clientY - mouse.last) / Math.max(1,dt) * 1000;
  mouse.last = event.clientY; mouse.time = event.timeStamp;
  move(event.clientY - mouse.y);
});
stage.addEventListener('pointerup', event => {
  if (!mouse) return;
  const velocity = event.timeStamp - mouse.time > 100 ? 0 : mouse.velocity;
  finish(shouldCommit(currentDy,velocity,stage.clientHeight));
  mouse = null;
});
stage.addEventListener('pointercancel', () => { if (mouse) { mouse = null; finish(false); } });
window.addEventListener('blur', () => { if (gesture.active) gesture.cancel(); if (mouse) { mouse = null; finish(false); } });
window.addEventListener('keydown', event => {
  if (!event.altKey || !['ArrowUp','ArrowDown'].includes(event.key)) return;
  event.preventDefault(); navigate(event.key === 'ArrowUp' ? 1 : -1);
});
back.addEventListener('click', () => navigate(-1));
forward.addEventListener('click', () => navigate(1));
document.querySelectorAll('[data-mode]').forEach(button => button.addEventListener('click', () => {
  if (busy) return;
  mode = button.dataset.mode;
  render();
}));
picker.addEventListener('click', () => {
  const list = document.querySelector('#session-list');
  list.replaceChildren(...data[mode].map(session => {
    const button = element('button','',session.title);
    button.setAttribute('aria-current', session.id === history().current);
    button.addEventListener('click', () => {
      history().visit(session.id);
      render();
      dialog.close();
    });
    return button;
  }));
  dialog.showModal();
});
document.querySelector('#close-dialog').addEventListener('click', () => dialog.close());
if (window.visualViewport) {
  const viewport = window.visualViewport;
  const resize = () => {
    if (window.innerWidth <= 600) document.querySelector('.prototype').style.height = `${viewport.height}px`;
  };
  viewport.addEventListener('resize', resize);
  resize();
}
render();
