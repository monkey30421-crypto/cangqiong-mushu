import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,mkdir,writeFile,readFile,stat,utimes,rm,readdir} from 'node:fs/promises';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
import {previewResource,previewSnapshot} from '../scripts/preview-resources.mjs';
import {syncSpineExport} from '../scripts/spine-source.mjs';

async function fixture(t){
 const root=await mkdtemp(join(tmpdir(),'spine-preview-resource-')),dir=join(root,'assets/actor');await mkdir(dir,{recursive:true});
 const source={skeleton:{spine:'4.3.26',hash:'original'},bones:[{name:'root'}],animations:{idle:{}}};
 await writeFile(join(dir,'actor.spine-json'),JSON.stringify(source));
 await writeFile(join(dir,'actor.atlas'),'a.png\nsize:1,1\nfilter:Linear,Linear\npart-a\nbounds:0,0,1,1\n\nb.png\nsize:1,1\nfilter:Linear,Linear\npart-b\nbounds:0,0,1,1\n');
 await writeFile(join(dir,'a.png'),'first texture');await writeFile(join(dir,'b.png'),'second texture');
 await writeFile(join(dir,'actor-data.tres'),'[gd_resource type="SpineSkeletonDataResource"]\n[ext_resource path="res://assets/actor/actor.spine-json"]\n[ext_resource path="res://assets/actor/actor.atlas"]\n');
 t.after(()=>rm(root,{recursive:true,force:true}));return {root,dir,source,path:'res://assets/actor/actor-data.tres'};
}
test('版本覆盖实际骨骼、图集和所有贴图；相同时间戳替换也能识别',async t=>{
 const f=await fixture(t),a=await previewResource(f.path,f.root);assert.equal(a.textures.length,2);assert.equal((await previewResource(f.path,f.root)).revision,a.revision);
 const before=await stat(join(f.dir,'b.png'));await writeFile(join(f.dir,'b.png'),'replaced texture');await utimes(join(f.dir,'b.png'),before.atime,before.mtime);
 const b=await previewResource(f.path,f.root);assert.notEqual(b.revision,a.revision);
 await writeFile(join(f.dir,'actor.atlas'),(await readFile(join(f.dir,'actor.atlas'),'utf8'))+'\n');const c=await previewResource(f.path,f.root);assert.notEqual(c.revision,b.revision);
 f.source.skeleton.hash='replacement';await writeFile(join(f.dir,'actor.spine-json'),JSON.stringify(f.source));assert.notEqual((await previewResource(f.path,f.root)).revision,c.revision);
 await assert.rejects(()=>previewSnapshot(['res://assets/../../etc/passwd'],f.root));
});
test('较新的 JSON 导出同步到游戏骨骼且备份原文件，较新的原生骨骼优先',async t=>{
 const f=await fixture(t),canonical=join(f.dir,'actor.spine-json'),exported=join(f.dir,'actor.json'),backups=join(f.root,'backups');
 const old=await readFile(canonical);f.source.skeleton.hash='new-export';await writeFile(exported,JSON.stringify(f.source));const future=new Date(Date.now()+5000);await utimes(exported,future,future);
 assert.equal((await syncSpineExport(canonical,backups)).updated,true);assert.equal(JSON.parse(await readFile(canonical,'utf8')).skeleton.hash,'new-export');assert.equal((await readdir(backups)).length,1);assert.deepEqual(await readFile(join(backups,(await readdir(backups))[0])),old);
 f.source.skeleton.hash='native-newer';await writeFile(canonical,JSON.stringify(f.source));const later=new Date(Date.now()+10000);await utimes(canonical,later,later);await syncSpineExport(canonical,backups);assert.equal(JSON.parse(await readFile(canonical,'utf8')).skeleton.hash,'native-newer');
});
test('未写完的 JSON 不覆盖已可用的游戏骨骼',async t=>{
 const f=await fixture(t),canonical=join(f.dir,'actor.spine-json'),before=await readFile(canonical),exported=join(f.dir,'actor.json');await writeFile(exported,'{"skeleton":');const later=new Date(Date.now()+1000);await utimes(exported,later,later);
 assert.equal((await syncSpineExport(canonical,join(f.root,'backups'))).pending,true);assert.deepEqual(await readFile(canonical),before);
});
