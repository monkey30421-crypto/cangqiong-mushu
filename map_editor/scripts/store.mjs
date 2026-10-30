import {readFile,writeFile,rename,mkdir,copyFile,readdir,realpath,stat,unlink} from 'node:fs/promises';
import {resolve,join,dirname,sep} from 'node:path';
import {createHash} from 'node:crypto';
import {homedir} from 'node:os';
import {fileURLToPath} from 'node:url';
import {syncSpineExport} from './spine-source.mjs';
export const editorRoot=resolve(dirname(fileURLToPath(import.meta.url)),'..');
export const gameRoot=resolve(editorRoot,'../godot_demo');
export const userRoot=join(homedir(),'Library/Application Support/Godot/app_userdata/苍穹母树：初枝试炼 Demo');
export const clone=value=>structuredClone(value);
export const hash=value=>createHash('sha256').update(JSON.stringify(value)).digest('hex');
export async function json(path,fallback){try{return JSON.parse(await readFile(path,'utf8'));}catch(error){if(error.code==='ENOENT'&&fallback!==undefined)return clone(fallback);throw error;}}
export async function files(path){let entries;try{entries=await readdir(path,{withFileTypes:true});}catch(e){if(e.code==='ENOENT')return [];throw e;}const out=[];for(const entry of entries){const file=join(path,entry.name);if(entry.isDirectory())out.push(...await files(file));else if(entry.isFile())out.push(file);}return out;}
export async function resource(path,root=gameRoot){
 if(typeof path!=='string'||!path.startsWith('res://assets/')||path.includes('..')||path.includes('\\'))throw Error('资源必须位于游戏 assets 目录内');
 const assets=await realpath(join(root,'assets')),file=await realpath(join(root,path.slice(6)));
 if(!file.startsWith(assets+sep)||(await stat(file)).isDirectory())throw Error('资源路径无效');return file;
}
export async function spine(path,root=gameRoot){
 const text=await readFile(await resource(path,root),'utf8');
 if(!text.includes('SpineSkeletonDataResource'))throw Error('不是 Spine 骨骼资源');
 const paths=[...text.matchAll(/path="(res:\/\/assets\/[^\"]+)"/g)].map(m=>m[1]);
 const skeleton=paths.find(p=>p.endsWith('.spine-json')||p.endsWith('.json')),atlas=paths.find(p=>p.endsWith('.atlas'));
 if(!skeleton||!atlas)throw Error('Spine 缺少骨骼或图集');
 const skeletonFile=await resource(skeleton,root);
 const sync=await syncSpineExport(skeletonFile,join(editorRoot,'backups/spine-sources'));
 const data=await json(skeletonFile);
 if(!data.skeleton||!data.animations)throw Error('Spine 骨骼无效');
 return {skeleton,atlas,skeletonData:data.skeleton,animations:data.animations,exportSource:sync.exported?skeleton.replace(/\.spine-json$/,'.json'):null,sourcePending:sync.pending||false};
}
export async function modelOptions(root=gameRoot){const list=[];for(const dir of ['character/art/monsters','character/art/player_animations'])for(const file of await files(join(root,'assets',dir)))if(file.endsWith('.tres')){const path='res://'+file.slice(root.length+1).split(sep).join('/');try{await spine(path,root);list.push(path);}catch{}}return list.sort();}
export function number(value,label,min=0,max=10000){if(typeof value!=='number'||!Number.isFinite(value)||value<min||value>max)throw Error(`${label}必须在 ${min}–${max} 之间`);return value;}
export function name(value,label='名称'){if(typeof value!=='string'||!value.trim()||value.length>100)throw Error(`${label}不能为空，且不能超过 100 字`);return value.trim();}
let queue=Promise.resolve();
export function locked(callback){const result=queue.then(callback);queue=result.catch(()=>{});return result;}
// Stage all files before changing any original. A failed write restores completed files.
export async function transaction(entries){
 const prepared=[];
 try{
  for(const [path,value] of entries){
   await mkdir(dirname(path),{recursive:true});
   let original=null;try{original=await readFile(path);}catch(e){if(e.code!=='ENOENT')throw e;}
   const tmp=path+'.editor-tmp';await writeFile(tmp,JSON.stringify(value,null,2)+'\n');prepared.push({path,tmp,original});
  }
  for(const item of prepared){if(item.original)await writeFile(item.path+'.bak',item.original);await rename(item.tmp,item.path);item.done=true;}
 }catch(error){for(const item of prepared){if(item.done){if(item.original)await writeFile(item.path,item.original);else await unlink(item.path).catch(()=>{});}await unlink(item.tmp).catch(()=>{});}throw error;}
}
export async function initialBackup(root=gameRoot,runtime=userRoot){
 const folder=join(editorRoot,'backups','restore-'+new Date().toISOString().replace(/[:.]/g,'-'));
 await mkdir(folder,{recursive:true});
 for(const file of await files(join(root,'config')))if(file.endsWith('.json')||file.endsWith('.bak'))await copyFile(file,join(folder,file.split(sep).at(-1)));
 for(const file of ['city_walkable_area.json','city_spawn_area.json','dungeon_area_editor.json']){try{await copyFile(join(runtime,file),join(folder,'user-'+file));}catch(e){if(e.code!=='ENOENT')throw e;}}
 return folder;
}
