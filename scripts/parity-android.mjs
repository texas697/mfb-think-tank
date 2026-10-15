import {spawn} from 'node:child_process';
import {mkdir, writeFile} from 'node:fs/promises';

const device = process.argv[2] || 'emulator-5554';
const fixture = process.env.PARITY_FIXTURE_URL || 'http://127.0.0.1:4175';
await mkdir('build', {recursive:true});
async function adb(args) {
  return new Promise((resolve,reject) => {
    const child=spawn('adb',['-s',device,...args]);
    const output=[]; let errors='';
    child.stdout.on('data',chunk=>output.push(chunk));
    child.stderr.on('data',chunk=>errors+=chunk);
    child.on('error',reject);
    child.on('exit',code=>code===0?resolve(Buffer.concat(output)):reject(new Error(errors)));
  });
}
await adb(['reverse','tcp:4175','tcp:4175']);
await adb(['shell','input','keyevent','KEYCODE_WAKEUP']);
await adb(['shell','wm','dismiss-keyguard']);
const runner=spawn('flutter',[
  'test','integration_test/parity_test.dart','-d',device,
  '--dart-define-from-file=config/app_config.json',
  `--dart-define=PARITY_FIXTURE_URL=${fixture}`,
],{stdio:['inherit','pipe','inherit']});
const pending=[]; const seen=new Set(); let output=''; let hasFailed=false;
const track = operation => pending.push(operation.catch(error => {
  hasFailed=true;process.stderr.write(`${error}\n`);
}));
runner.stdout.on('data',chunk=>{
  process.stdout.write(chunk); output=(output+chunk).slice(-4096);
  for(const name of ['dashboard','media','telegram']) {
    if(!output.includes(`PARITY_CAPTURE_${name}`)||seen.has(name))continue;
    seen.add(name);
    track(adb(['exec-out','screencap','-p'])
      .then(bytes=>writeFile(`build/parity-${name}-android.png`,bytes)));
  }
  if(output.includes('PARITY_PIP_STARTED')&&!seen.has('pip')) {
    seen.add('pip');
    track((async()=>{
      try {
        const state=await adb(['shell','dumpsys','activity','activities']);
        await writeFile('build/parity-pip-activity.txt',state);
        if(!state.toString().includes('mode=pinned'))throw new Error('Android did not report a pinned PiP task');
        await writeFile('build/parity-pip-android.png',await adb(['exec-out','screencap','-p']));
      } finally {
        await adb(['shell','am','start','-n','com.mfbservicesinc.mfb_think_tank/.MainActivity']);
      }
    })());
  }
});
const status=await new Promise((resolve,reject)=>{
  runner.on('error',reject);runner.on('exit',resolve);
});
for(const result of await Promise.allSettled(pending)) {
  if(result.status==='rejected'){hasFailed=true;process.stderr.write(`${result.reason}\n`);}
}
if(status===0&&seen.size!==4){hasFailed=true;process.stderr.write('Missing native evidence checkpoints\n');}
process.exitCode=hasFailed?1:status??1;
