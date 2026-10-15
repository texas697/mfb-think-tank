import http from 'node:http';
import {readFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';

const upstream = new URL(process.env.CRUCIX_FIXTURE_URL || 'http://127.0.0.1:4173');
const port = Number(process.env.PORT || 4175);
const root = fileURLToPath(new URL('../../crucix/test/fixtures/', import.meta.url));
const counters = {sessions: 0, privateImages: 0, privateFiles: 0, events: 0};
const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNQ8Ej6DwADIAHKrnNmngAAAABJRU5ErkJggg==', 'base64');
const dialogs = [
  {id:'-1001', title:'Iran updates', group:'Iran', type:'channel', hasPhoto:true, unreadCount:2,
    lastMessage:{id:3,text:'A translated field update',date:'2026-10-15T12:00:00Z'}},
  {id:'-1002', title:'Europe news', group:'Europe', type:'channel', hasPhoto:false, unreadCount:0},
];
const messages = [
  {id:3,text:'گزارش میدانی',date:'2026-10-15T12:00:00Z',senderId:'-1001',out:false,
    translation:{text:'A translated field update',from:'fa'},
    webpage:{url:'https://example.com/report',displayUrl:'example.com/report',siteName:'Field report',title:'Regional developments',description:'A source-linked intelligence update.',hasPhoto:true}},
  {id:2,text:'Photo from the channel',date:'2026-10-15T11:00:00Z',out:false,
    media:{kind:'photo',mime:'image/png',width:1,height:1,size:png.length,tooLarge:false}},
  {id:1,text:'Video update',date:'2026-10-15T10:00:00Z',out:false,
    media:{kind:'video',mime:'video/mp4',width:320,height:180,size:10000,duration:6,tooLarge:false}},
];
const json = (res, status, data) => {res.writeHead(status, {'content-type':'application/json','cache-control':'no-store'}); res.end(JSON.stringify(data));};
const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://127.0.0.1');
  if (url.pathname === '/__fixture/stats') return json(res,200,counters);
  if (url.pathname === '/login') {
    res.writeHead(200,{'content-type':'text/html'});
    return res.end('<!doctype html><meta name="viewport" content="width=device-width,initial-scale=1"><body style="background:#05070b;color:white">Fixture sign-in bootstrap</body>');
  }
  if (url.pathname === '/api/session' && req.method === 'POST') {
    let body=''; for await (const chunk of req) body+=chunk;
    if (body.length > 4096 || JSON.parse(body).idToken !== 'mobile-fixture-token') return json(res,401,{error:'Fixture token required'});
    counters.sessions++;
    res.setHeader('set-cookie','__session=mobile-fixture; Path=/; HttpOnly; SameSite=Lax');
    return json(res,200,{ok:true,user:{uid:'fixture'}});
  }
  const authenticated = req.headers.authorization === 'Bearer mobile-fixture-token' || req.headers.cookie?.includes('__session=mobile-fixture');
  if (url.pathname === '/' && !authenticated) {res.writeHead(302,{location:'/login'});return res.end();}
  if (url.pathname.startsWith('/api/') && !authenticated) return json(res,401,{error:'Authentication required'});
  if (url.pathname === '/api/telegram/status') return json(res,200,{configured:true,authenticated:true,connected:true});
  if (url.pathname === '/api/telegram/dialogs') return json(res,200,{dialogs});
  if (url.pathname.startsWith('/api/telegram/messages/')) return json(res,200,{messages,translated:true});
  if (/^\/api\/telegram\/(avatar|media)\//.test(url.pathname)) {
    if (url.searchParams.get('kind') === 'file') {
      counters.privateFiles++;
      try {res.writeHead(200,{'content-type':'video/mp4'});res.end(readFileSync(new URL('../build/parity-fixtures/clip.mp4',import.meta.url)));}
      catch {json(res,404,{error:'Generate build/parity-fixtures/clip.mp4 with the documented ffmpeg command'});}
      return;
    }
    counters.privateImages++;res.writeHead(200,{'content-type':'image/png'});return res.end(png);
  }
  if (url.pathname.startsWith('/fixture-media/')) {
    const name=url.pathname.split('/').at(-1);
    if (!['index.m3u8','seg0.ts'].includes(name)) return json(res,404,{});
    res.writeHead(200,{'content-type':name.endsWith('m3u8')?'application/vnd.apple.mpegurl':'video/mp2t'});
    return res.end(readFileSync(`${root}/vendor/hls-fixture/${name}`));
  }
  const proxy=http.request(new URL(req.url,upstream),{method:req.method,headers:{...req.headers,host:upstream.host}},(response)=>{
    res.writeHead(response.statusCode,response.headers);response.pipe(res);
  });
  if(url.pathname==='/events'){counters.events++;res.on('close',()=>{counters.events--;proxy.destroy();});}
  proxy.on('error',()=>{if(!res.headersSent)json(res,502,{error:'Start the Crucix fixture server on port 4173 first'});else res.end();});
  req.pipe(proxy);
});
server.listen(port,'127.0.0.1',()=>process.stdout.write(`Mobile parity fixture: http://127.0.0.1:${port}\n`));
for(const signal of ['SIGTERM','SIGINT']) process.on(signal,()=>server.close(()=>process.exit(0)));
