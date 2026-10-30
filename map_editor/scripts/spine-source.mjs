import {readFile,writeFile,stat,mkdir,rename,realpath} from 'node:fs/promises';
import {dirname,basename,join,sep} from 'node:path';
import {createHash} from 'node:crypto';

const pending=new Map();
// Spine exports use .json; Godot imports the same bytes as .spine-json.
// A newer canonical file wins, so directly edited runtime sources are preserved.
export async function syncSpineExport(canonical,backupRoot){
 if(!canonical.endsWith('.spine-json'))return {};
 const run=async()=>{
  const exported=canonical.replace(/\.spine-json$/,'.json');
  let sourceStat;try{sourceStat=await stat(exported);}catch(e){if(e.code==='ENOENT')return {};throw e;}
  if(!(await realpath(exported)).startsWith(await realpath(dirname(canonical))+sep))throw Error('Spine 导出源必须位于同一资源目录');
  const targetStat=await stat(canonical);
  if(sourceStat.mtimeMs<=targetStat.mtimeMs)return {exported};
  const [bytes,previous]=await Promise.all([readFile(exported),readFile(canonical)]);
  if(bytes.equals(previous))return {exported};
  let value;try{value=JSON.parse(bytes.toString('utf8'));}catch{return {exported,pending:true};}
  if(!value?.skeleton||!value.animations||!Array.isArray(value.bones))return {exported,pending:true};
  const digest=createHash('sha256').update(canonical).update(previous).digest('hex').slice(0,20);
  await mkdir(backupRoot,{recursive:true});
  const backup=join(backupRoot,basename(canonical)+'.'+digest+'.bak');
  await writeFile(backup,previous,{flag:'wx'}).catch(e=>{if(e.code!=='EEXIST')throw e;});
  const temporary=canonical+'.editor-source-tmp';
  await writeFile(temporary,bytes);await rename(temporary,canonical);
  return {exported,updated:true,backup};
 };
 const result=(pending.get(canonical)||Promise.resolve()).catch(()=>{}).then(run);
 pending.set(canonical,result);
 try{return await result;}finally{if(pending.get(canonical)===result)pending.delete(canonical);}
}
