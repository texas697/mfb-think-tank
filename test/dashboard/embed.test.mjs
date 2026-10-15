import {readFileSync} from 'node:fs';
import {runInNewContext} from 'node:vm';
import assert from 'node:assert/strict';
import test from 'node:test';

const source = readFileSync(new URL('../../assets/dashboard/embed.js',import.meta.url),'utf8').replace('__MFB_NONCE__','"fixture-nonce"');
function browser({chips=[],timeButtons=[],href='https://api.example/'} = {}) {
  const messages=[], calls=[], events={};
  const context={URL,JSON,setTimeout:(fn,delay)=>delay>1000?0:setTimeout(fn,delay),clearTimeout,
    MutationObserver:class {observe(){} disconnect(){}},localStorage:{getItem:()=>null}, location:new URL(href),scrollY:0,scrollTo(_x,y){context.scrollY=y;},__mfbRestoreScroll:320,
    MfbDashboard:{postMessage:(raw)=>messages.push(JSON.parse(raw))},
    document:{body:{},querySelector:(selector)=>selector==='#mapLegend'&&chips.length?{}:timeButtons.find(b=>b.isOn)??null,
      querySelectorAll:(selector)=>selector==='[data-layer]'?chips:selector==='.crucix-map-legend-time'?timeButtons:[],createElement:()=>({}),head:{appendChild(){}},addEventListener:(name,handler)=>events[name]=handler},
    addEventListener:(name,handler)=>events[name]=handler,
    fetch:async(input,init)=>{calls.push({input,init});return {ok:true};},
    history:{pushState(_state,_unused,url){context.location.href=new URL(url,context.location.href).href;},replaceState(){}}
  };
  context.window=context;runInNewContext(source,context);
  return {context,messages,calls,events};
}
test('rectangle and polygon area selections match the backend coordinate contract',async()=>{
  const {context,calls}=browser();
  await context.fetch('/api/map/region',{method:'POST',body:JSON.stringify({shape:{kind:'rect',sw:{lng:1,lat:2},ne:{lng:3,lat:4}},mode:'brief'})});
  assert.deepEqual(JSON.parse(calls[0].init.body),{shape:{kind:'polygon',ring:[[1,2],[3,2],[3,4],[1,4],[1,2]]},mode:'brief'});
  await context.fetch('/api/map/region',{body:JSON.stringify({shape:{kind:'poly',ring:[{lng:1,lat:2},{lng:3,lat:4},{lng:5,lat:6}]}})});
  assert.deepEqual(JSON.parse(calls[1].init.body).shape,{kind:'polygon',ring:[[1,2],[3,4],[5,6]]});
});
test('already valid circles and unrelated requests are preserved',async()=>{
  const {context,calls}=browser();
  const body=JSON.stringify({shape:{kind:'circle',center:{lat:1,lng:2},radiusKm:20}});
  await context.fetch('/api/map/region',{body});assert.equal(calls[0].init.body,body);
  await context.fetch('/api/ideas',{body:'{}'});assert.equal(calls[1].init.body,'{}');
});
test('fetch accepts URL and Request inputs without changing the original request',async()=>{
  const {context,calls}=browser();
  const url=new URL('https://api.example/api/data');
  const request=new Request('https://api.example/api/health');
  await context.fetch(url);await context.fetch(request);
  assert.equal(calls[0].input,url);assert.equal(calls[1].input,request);
});
test('SPA navigation hands native destinations to the app and includes nonce',()=>{
  const {context,messages}=browser();
  context.history.pushState({},'', '/media/rt?grid=1');
  assert.deepEqual(messages.at(-1),{type:'navigate',url:'https://api.example/media/rt?grid=1',nonce:'fixture-nonce'});
});
test('external links are intercepted before browser navigation',()=>{
  const {events,messages}=browser();let prevented=false;
  events.click({target:{closest:()=>({href:'https://news.example/story'})},preventDefault(){prevented=true;},stopImmediatePropagation(){}});
  assert.equal(prevented,true);assert.equal(messages.at(-1).url,'https://news.example/story');
});

test('tab restoration preserves layer, time and scroll preferences',async()=>{
  const chip=(layer)=>({dataset:{layer},isOff:false,classList:{contains(){return this.owner.isOff;},owner:null},click(){this.isOff=!this.isOff;}});
  const air=chip('air'), thermal=chip('thermal');
  air.classList.owner=air;thermal.classList.owner=thermal;
  const time={value:'24h',isOn:false,click(){this.isOn=true;}};
  const {context,messages}=browser({chips:[air,thermal],timeButtons:[time],href:'https://api.example/?_mobileHidden=thermal&_mobileTime=24h'});
  await new Promise(resolve=>setTimeout(resolve,150));
  assert.equal(thermal.isOff,true);assert.equal(air.isOff,false);assert.equal(time.isOn,true);assert.equal(context.scrollY,320);
  const snapshot=messages.findLast(message=>message.type==='location');
  assert.equal(new URL(snapshot.url).searchParams.get('_mobileHidden'),'thermal');
  assert.equal(new URL(snapshot.url).searchParams.get('_mobileTime'),'24h');
});
