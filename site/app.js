import {SessionHistory, historyStep, shouldCommit, shouldOpenOverview, cardScaleAt, defaultSettings} from './history.js';
import {galleries} from './gallery.js';

const stage = document.querySelector('#stage');
const cards = document.querySelector('#cards');
const older = document.querySelector('#older');
const newer = document.querySelector('#newer');
const position = document.querySelector('#position');
const watch = document.querySelector('#watch');
const browse = document.querySelector('#browse');
const close = document.querySelector('#close-stack');
const help = document.querySelector('#preview-help');
const histories = Object.fromEntries(Object.entries(galleries).map(([key, entries]) => [key,new SessionHistory(entries.map(([id])=>id))]));
const reduceMotion = () => matchMedia('(prefers-reduced-motion: reduce)').matches;
let mode = 'chats';
let overview = false;
let busy = false;
let drag = null;
let cardElements = [];
let overviewTrigger = null;
const history = () => histories[mode];
const title = id => galleries[mode].find(([key])=>key===id)?.[1] ?? '';

function updateControls() {
  const h = history();
  older.disabled = busy || overview || !h.destination(-1);
  newer.disabled = busy || overview || !h.destination(1);
  watch.disabled = busy || overview;
  browse.disabled = busy || overview;
  document.querySelectorAll('[data-mode]').forEach(button => {
    button.disabled = busy;
    button.setAttribute('aria-pressed',String(button.dataset.mode===mode));
  });
  position.value = `${title(h.current)} · ${h.cursor+1} / ${h.entries.length}`;
  stage.setAttribute('aria-label',overview ? 'Conversation stack. Choose a chat.' : `${title(h.current)}. Drag to explore conversation history.`);
  stage.dataset.mode = mode;
  stage.dataset.cursor = String(h.cursor);
  stage.dataset.overview = String(overview);
}

function arrange(distance=0) {
  if (overview) return;
  const height = stage.clientHeight;
  const step = historyStep(distance);
  const dy = distance && !history().destination(step) ? distance * .17 : distance;
  const scale = cardScaleAt(dy,height);
  const stride = height * scale + defaultSettings.cardSpacing;
  cardElements.forEach((element,index) => {
    const relative = index-history().cursor;
    element.style.transform = `translateY(${dy+relative*stride}px) scale(${scale})`;
    element.style.zIndex = String(10-Math.abs(relative));
    element.style.visibility = Math.abs(relative)<=1 ? 'visible' : 'hidden';
    element.tabIndex = -1;
    element.setAttribute('aria-current',String(relative===0));
  });
  stage.style.setProperty('--touch-y',`${Math.max(20,Math.min(85,46+dy/height*100))}%`);
}

function render() {
  cards.replaceChildren();
  cardElements = history().entries.map(id => {
    const button = document.createElement('button');
    button.type='button'; button.className='preview-card';
    button.setAttribute('aria-label',`Open ${title(id)}`);
    const caption = document.createElement('span');
    caption.className='card-caption'; caption.textContent=title(id);
    const image = document.createElement('img');
    image.src=`assets/screens/${id}.webp`;
    image.alt=`Native prototype screenshot: ${title(id)}`;
    image.width=430; image.height=937; image.draggable=false;
    image.loading='eager';
    button.append(caption,image);
    button.addEventListener('click',()=>{ if(overview && !busy) closeOverview(history().entries.indexOf(id)); });
    cards.append(button);
    return button;
  });
  arrange(); updateControls();
}

async function animateTo(distance,duration=300,from=0) {
  const start=performance.now();
  return new Promise(resolve=>{
    function frame(now) {
      const progress=reduceMotion()?1:Math.min(1,(now-start)/duration);
      const eased=1-Math.pow(1-progress,3);
      arrange(from+(distance-from)*eased);
      if(progress<1) requestAnimationFrame(frame); else resolve();
    }
    requestAnimationFrame(frame);
  });
}

async function navigate(step) {
  if(busy || overview || !history().destination(step)) return;
  busy=true; updateControls();
  await animateTo(-step*(stage.clientHeight+defaultSettings.cardSpacing),320);
  history().move(step); busy=false;
  arrange(); updateControls();
}

function openOverview(trigger=document.activeElement) {
  if(busy || overview) return;
  overviewTrigger=[browse,watch].includes(trigger)?trigger:stage;
  overview=true;
  stage.classList.add('overview'); stage.classList.remove('dragging','watching');
  cardElements.forEach((element,index)=>{
    element.style.transform=''; element.style.zIndex=''; element.style.visibility='';
    element.tabIndex=0; element.setAttribute('aria-current',String(index===history().cursor));
  });
  close.hidden=false;
  const current=cardElements[history().cursor];
  stage.scrollTop=Math.max(0,current.offsetTop-(stage.clientHeight-current.offsetHeight)/2);
  help.textContent='Scroll the cards with one finger. Tap a conversation to open it.';
  updateControls();
  current.focus({preventScroll:true});
}

function closeOverview(index=history().cursor) {
  if(busy || !overview) return;
  history().select(index); overview=false;
  stage.classList.remove('overview'); stage.scrollTop=0; close.hidden=true;
  help.replaceChildren('Drag down with one finger or your mouse here.',document.createElement('br'),'The native experiment uses three fingers.');
  arrange(); updateControls();
  const returnTo=overviewTrigger?.isConnected && !overviewTrigger.disabled?overviewTrigger:stage;
  returnTo.focus({preventScroll:true});
  overviewTrigger=null;
}

stage.addEventListener('pointerdown',event=>{
  if(busy || overview || event.button!==0) return;
  drag={id:event.pointerId,y:event.clientY,lastY:event.clientY,time:event.timeStamp,velocity:0,dy:0};
  stage.setPointerCapture(event.pointerId); stage.classList.add('dragging');
});
stage.addEventListener('pointermove',event=>{
  if(!drag || event.pointerId!==drag.id) return;
  drag.velocity=(event.clientY-drag.lastY)/Math.max(1,event.timeStamp-drag.time)*1000;
  drag.lastY=event.clientY; drag.time=event.timeStamp; drag.dy=event.clientY-drag.y;
  arrange(drag.dy);
});
async function release(event,cancelled=false) {
  if(!drag || event.pointerId!==drag.id) return;
  const {dy,time,velocity}=drag;
  drag=null; stage.classList.remove('dragging');
  const speed=event.timeStamp-time>100?0:velocity;
  const step=historyStep(dy);
  if(!cancelled && shouldOpenOverview(dy,speed,stage.clientHeight)) { openOverview(); return; }
  const commit=!cancelled && shouldCommit(dy,speed,stage.clientHeight) && history().destination(step);
  busy=true; updateControls();
  await animateTo(commit?-step*(stage.clientHeight+defaultSettings.cardSpacing):0,280,dy);
  if(commit) history().move(step);
  busy=false;
  arrange(); updateControls();
}
stage.addEventListener('pointerup',event=>release(event));
stage.addEventListener('pointercancel',event=>release(event,true));
stage.addEventListener('lostpointercapture',event=>{ if(drag) release(event,true); });
window.addEventListener('blur',()=>{ drag=null; stage.classList.remove('dragging'); arrange(); });
stage.addEventListener('keydown',event=>{
  if(event.key==='Escape') { closeOverview(); event.preventDefault(); }
  if(!overview && ['ArrowDown','ArrowUp'].includes(event.key)) {
    event.preventDefault(); navigate(event.key==='ArrowDown'?-1:1);
  }
});
older.addEventListener('click',()=>navigate(-1));
newer.addEventListener('click',()=>navigate(1));
browse.addEventListener('click',()=>openOverview(browse));
close.addEventListener('click',()=>closeOverview());
document.querySelectorAll('[data-mode]').forEach(button=>button.addEventListener('click',()=>{
  if(busy) return;
  if(overview) closeOverview();
  mode=button.dataset.mode; render();
}));
watch.addEventListener('click',async()=>{
  if(busy || overview) return;
  busy=true; stage.classList.add('watching'); updateControls();
  const distance=history().destination(-1)?1:-1;
  await animateTo(distance*145,1000);
  stage.classList.remove('watching'); busy=false; openOverview(watch);
});
new ResizeObserver(()=>{if(!drag && !busy) arrange();}).observe(stage);
render();
