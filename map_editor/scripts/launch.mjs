import {spawn,execFileSync} from 'node:child_process';
import {open} from 'node:fs/promises';
import {join} from 'node:path';
import {editorRoot,gameRoot} from './store.mjs';
const route=process.argv[2]||'/',port=Number(process.env.PORT||3000),base=`http://127.0.0.1:${port}`;
async function healthy(){try{const response=await fetch(base+'/api/health',{signal:AbortSignal.timeout(1500)});if(!response.ok)return false;const data=await response.json();return data.restored&&data.root===gameRoot;}catch{return false;}}
if(!await healthy()){
 const log=await open(join(editorRoot,'editor.log'),'a');
 const child=spawn(process.execPath,[join(editorRoot,'scripts/dev.mjs')],{cwd:editorRoot,detached:true,stdio:['ignore',log.fd,log.fd],env:{...process.env,PORT:String(port)}});child.unref();await log.close();
 for(let i=0;i<60;i++){if(await healthy())break;await new Promise(r=>setTimeout(r,250));}
}
if(!await healthy()){console.error(`编辑器未能启动。请查看 ${join(editorRoot,'editor.log')}；如果 ${port} 端口被旧服务占用，请先关闭旧服务。`);process.exitCode=1;}else{const url=`http://localhost:${port}${route}`;console.log('编辑器已就绪：'+url);if(!process.argv.includes('--no-open'))execFileSync('open',[url]);}
