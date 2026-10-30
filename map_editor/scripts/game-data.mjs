import {readFile} from 'node:fs/promises';
import {join} from 'node:path';
import {gameRoot,json,resource,spine,modelOptions,clone,hash,number,name,locked,transaction} from './store.mjs';
export const actionDefinitions=[[1001,'待机'],[1002,'走路'],[1003,'跑步'],[1004,'跳跃上升'],[1005,'跳跃下落'],[1006,'闪避'],[1007,'受击'],[1008,'原地死亡'],[1010,'倒地起身前滚'],[1011,'倒地起身后滚'],[1012,'起身'],[1013,'击飞中'],[1014,'击飞落地'],[1015,'躺地循环'],[1016,'跪地循环'],[2001,'普通攻击1'],[2002,'普通攻击2'],[2003,'普通攻击3'],[2004,'跳跃攻击'],[2005,'闪避攻击']];
export const monsterDefinitions=[['idle','待机'],['move_front','前进'],['move_back','后退'],['attack1','攻击1'],['attack2','攻击2'],['skill1','技能1'],['skill2','技能2'],['hurt','受击'],['floated','击飞中'],['down_fly','击飞落地'],['lying_loop','躺地循环'],['down','原地死亡'],['getup','起身']];
export const qualities=['枯痕','新芽','生叶','灵露','灵枝','冠辉','母源'];
export const qualityColors=['#999999','#eeeeee','#6ebd72','#6aa5e7','#bb80e3','#edbf5b','#ed7777'];
export const types={material:'材料',consumable:'消耗品',chest:'宝箱',equipment:'装备',quest:'任务',skill:'技能',currency:'货币',other:'其他'};
const configs={characters:'characters.json',actions:'character_actions.json',monsters:'monster_actions.json',items:'inventory.json'};
export function timelineEnd(value){if(Array.isArray(value))return value.reduce((max,item)=>Math.max(max,timelineEnd(item)),0);if(value&&typeof value==='object')return Math.max(Number.isFinite(value.time)?value.time:0,...Object.values(value).map(timelineEnd));return 0;}
const clips=animations=>Object.fromEntries(Object.entries(animations).map(([key,value])=>[key,{duration:timelineEnd(value),events:value.events||[],nativeSpine:true}]));
export async function catalog(root=gameRoot){
 const registry=await json(join(root,'config/spine_effects.json'));
 const profiles=await json(join(root,'config/characters.json'));
 const hero=profiles.rows.find(r=>r.id===1);
 const rawHero=await spine(hero.modelResource,root);
 const effects=[];
 for(const file of registry.effects||[]){const source=await spine(file.resource,root);effects.push({...file,source:source.skeleton,animations:clips(source.animations)});}
 return {character:{file:rawHero.skeleton.split('/').at(-1),source:rawHero.skeleton,resource:hero.modelResource,animations:clips(rawHero.animations)},effects};
}
export async function readConfig(kind,root=gameRoot){if(!configs[kind])throw Error('未知配置');const config=await json(join(root,'config',configs[kind]));return {config,etag:hash(config)};}
export async function configPayload(kind,root=gameRoot){
 const base=await readConfig(kind,root);
 if(kind==='characters')return {...base,resources:await modelOptions(root),items:(await readConfig('items',root)).config.items};
 if(kind==='actions')return {...base,catalog:await catalog(root),definitions:actionDefinitions};
 if(kind==='items')return {...base,types,qualities,qualityColors,icons:await itemIcons(root)};
 const profiles=(await readConfig('characters',root)).config.rows.filter(p=>p.id>=101),cat=await catalog(root),libraries=[];
 for(const path of await modelOptions(root)){const info=await spine(path,root);libraries.push({path,animations:clips(info.animations),nativeSpine:true});}
 const config=clone(base.config);
 for(const profile of profiles)if(!config.monsters.some(m=>m.characterId===profile.id))config.monsters.push({characterId:profile.id,actions:monsterDefinitions.map(([key])=>({key,animation:null,upper:null,lower:null}))});
 return {...base,config,profiles,libraries,effects:cat.effects,definitions:monsterDefinitions};
}
async function itemIcons(root){const {files}=await import('./store.mjs');return (await files(join(root,'assets/items'))).filter(p=>p.endsWith('.png')).map(p=>'res://'+p.slice(root.length+1));}
function effectSelection(value,cat){if(value===null||value===undefined)return null;if(!value||!cat.effects.some(e=>e.file===value.file&&Object.hasOwn(e.animations,value.animation)))throw Error('特效文件或动画选择无效');return {file:value.file,animation:value.animation};}
export async function validateConfig(kind,input,root=gameRoot){
 if(!input||input.version!==1)throw Error('配置版本不正确');const result=clone(input);
 if(kind==='characters'){
  if(!Array.isArray(result.rows)||result.rows.length>300)throw Error('角色列表无效');const ids=new Set();const items=(await readConfig('items',root)).config.items;
  for(const row of result.rows){if(!Number.isInteger(row.id)||(row.id!==1&&row.id<101)||ids.has(row.id))throw Error('主角 ID 为1，怪物从101起，且不能重复');ids.add(row.id);row.name=name(row.name);number(row.x,'X',.1);number(row.h,'H',.1);row.shadowScalePercent??=100;number(row.shadowScalePercent,'阴影比例',0,1000);
   const file=await resource(row.modelResource,root);
   if(row.id===1){if(!file.endsWith('.tres'))throw Error('主角需要原生 Spine 骨骼资源（.tres）');const model=await spine(row.modelResource,root),actions=(await readConfig('actions',root)).config.rows;for(const action of actions)if(action.animation!=='__hold_last_frame__'&&!Object.hasOwn(model.animations,action.animation))throw Error(`模型缺少主角动作 ${action.animation}`);}
   else{if(!['normal','elite','mutation','boss'].includes(row.monsterType))throw Error('怪物类型无效');row.hitPushbackDistancePx??=40;number(row.hitPushbackDistancePx,'受击击退距离');row.canBeLaunched??=row.monsterType!=='boss';if(typeof row.canBeLaunched!=='boolean')throw Error('可被击飞需要选择是或否');if(file.endsWith('.tres'))await spine(row.modelResource,root);else if(!file.endsWith('.png'))throw Error('动画模型需要原生 Spine；PNG 仅作为静态贴图');}
   row.drops??=[];if(!Array.isArray(row.drops)||row.drops.length>100)throw Error('掉落列表无效');for(const drop of row.drops){if(!Object.hasOwn(items,drop.itemId))throw Error(`掉落道具 ${drop.itemId} 不存在`);number(drop.probability,'掉落概率',0,1);drop.minCount??=drop.count??1;drop.maxCount??=drop.count??drop.minCount;for(const n of [drop.minCount,drop.maxCount])if(!Number.isInteger(n)||n<1||n>9999)throw Error('掉落数量必须为1–9999的整数');if(drop.minCount>drop.maxCount)throw Error('最少数量不能大于最多数量');delete drop.count;}
  }
  for(const id of [1,101,102,103,104])if(!ids.has(id))throw Error(`不能删除正在使用的角色 ${id}`);
  result.rows.sort((a,b)=>a.id-b.id);
 }else if(kind==='items'){
  if(!result.items||Array.isArray(result.items))throw Error('道具列表无效');number(result.capacity,'背包容量',1,9999);
  for(const [id,item] of Object.entries(result.items)){if(!/^[a-zA-Z0-9_-]{1,80}$/.test(id))throw Error('道具 ID 仅允许字母、数字、下划线和短横线');item.name=name(item.name);if(!Object.hasOwn(types,item.type))throw Error('道具类型无效');number(item.quality,'品质',0,6);if(!Number.isInteger(item.quality))throw Error('品质必须为整数');await resource(item.icon,root);item.category={equipment:'equipment',quest:'quest',skill:'skill',currency:'currency'}[item.type]||'general';item.type_name=types[item.type];item.quality_name=qualities[item.quality];item.quality_color=qualityColors[item.quality];if(typeof item.description!=='string'||item.description.length>4000)throw Error('道具描述过长');}
  const profiles=(await readConfig('characters',root)).config.rows;for(const p of profiles)for(const drop of p.drops||[])if(!Object.hasOwn(result.items,drop.itemId))throw Error(`道具 ${drop.itemId} 正被 ${p.name} 的掉落配置引用`);
 }else if(kind==='actions'){
  const cat=await catalog(root);if(!Array.isArray(result.rows)||result.rows.length!==actionDefinitions.length)throw Error('动作数量不正确');const ids=new Set();
  for(const row of result.rows){if(ids.has(row.id)||!actionDefinitions.some(d=>d[0]===row.id))throw Error('动作 ID 重复或无效');ids.add(row.id);if(!cat.character.animations[row.animation]&&!([1015,1016].includes(row.id)&&row.animation==='__hold_last_frame__'))throw Error(`${row.id} 主角动画无效`);row.upper=effectSelection(row.upper,cat);row.lower=effectSelection(row.lower,cat);if(row.id>=2000)for(const key of ['attackDistancePx','longitudinalRangePx','heightRangePx','advanceDistancePx','advanceDurationMs','hitStopMs'])number(row[key],`${row.id} ${key}`,0,1000000);}
 }else if(kind==='monsters'){
  const payload=await configPayload('monsters',root),cat={effects:payload.effects},ids=new Set();if(!Array.isArray(result.monsters))throw Error('怪物动作列表无效');
  for(const monster of result.monsters){const profile=payload.profiles.find(p=>p.id===monster.characterId);if(!profile||ids.has(monster.characterId))throw Error('怪物 ID 无效或重复');ids.add(monster.characterId);const keys=new Set();if(!Array.isArray(monster.actions)||monster.actions.length!==monsterDefinitions.length)throw Error('怪物动作数量不正确');for(const row of monster.actions){if(keys.has(row.key)||!monsterDefinitions.some(d=>d[0]===row.key))throw Error('怪物动作重复或无效');keys.add(row.key);if(row.animation&&!payload.libraries.some(l=>l.path===row.animation.library&&l.animations[row.animation.name]))throw Error(`${row.key} 模型动画无效`);row.upper=effectSelection(row.upper,cat);row.lower=effectSelection(row.lower,cat);if(profile.monsterType!=='boss'&&['skill1','skill2'].includes(row.key)&&(row.animation||row.upper||row.lower))throw Error('仅首领可配置技能1、技能2');}}
 }else throw Error('未知配置');
 return result;
}
export async function saveConfig(kind,input,etag,root=gameRoot){return locked(async()=>{
 const current=await readConfig(kind,root);if(etag!==current.etag)throw Error('配置已被其他页面更新，请重新读取后保存');const config=await validateConfig(kind,input,root);
 config.revision=(Number(current.config.revision)||0)+1;config.updatedAt=new Date().toISOString();await transaction([[join(root,'config',configs[kind]),config]]);return {config,etag:hash(config)};
});}
