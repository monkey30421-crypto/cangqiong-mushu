import {readFile} from 'node:fs/promises';
import {posix} from 'node:path';
import {createHash} from 'node:crypto';
import {TextureAtlas} from '@esotericsoftware/spine-core';
import {resource,spine,gameRoot,hash} from './store.mjs';

export async function previewResource(path,root=gameRoot){
 let info=null,textures=[],dependencies=[path];
 if(path.endsWith('.tres')){
  info=await spine(path,root);
  const atlas=new TextureAtlas(await readFile(await resource(info.atlas,root),'utf8'));
  textures=atlas.pages.map(page=>({name:page.name,path:posix.dirname(info.atlas)+'/'+page.name}));
  dependencies.push(info.skeleton,info.atlas,...textures.map(t=>t.path));
 }else if(!path.endsWith('.png'))throw Error('预览资源需要 Spine 骨骼或静态 PNG');
 const digest=createHash('sha256');
 for(const dependency of [...new Set(dependencies)].sort())digest.update(dependency).update(await readFile(await resource(dependency,root)));
 return {path,revision:digest.digest('hex'),dependencies,textures,info};
}

export async function previewSnapshot(paths,root=gameRoot){
 if(!Array.isArray(paths)||paths.length<1||paths.length>8||paths.some(p=>typeof p!=='string'))throw Error('预览资源列表无效');
 const resources=[];
 for(const path of [...new Set(paths)]){
  const result=await previewResource(path,root);
  resources.push({path,revision:result.revision,pending:result.info?.sourcePending||false});
 }
 return {revision:hash(resources.map(r=>[r.path,r.revision])),resources};
}
