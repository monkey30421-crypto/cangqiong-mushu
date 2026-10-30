import {join} from 'node:path';
import {gameRoot,userRoot,json,clone,hash,transaction,locked,number} from './store.mjs';
const keys=['start','normal_1','normal_2','boss'];
const legacy=['start','normal_1','normal_2','normal_1','normal_2','boss'];
const titles={start:'起点 · 祭坛树',normal_1:'普通区域 · 前景一',normal_2:'普通区域 · 前景二',boss:'首领区域'};
const widths={start:2400,normal_1:5400,normal_2:5400,boss:3600};
const layers='res://assets/scene/maps/backgrounds/dungeon_floor1/layers/';
const defaults=(w)=>[[98,540],[w-98,540],[w-98,850],[98,850]];
export async function readMaps(root=gameRoot,runtime=userRoot){
 const city=await json(join(root,'config/main_city_editor.json'));
 const projectDungeon=await json(join(root,'config/dungeon_area_editor.json'));
 const dungeon=await json(join(runtime,'dungeon_area_editor.json'),projectDungeon);
 const walk=await json(join(runtime,'city_walkable_area.json'),city.walkable_area);
 const spawn=await json(join(runtime,'city_spawn_area.json'),city.spawn_area);
 const maps=[{id:'main-city-current',name:'初枝集 · 主城',width:5400,height:1200,kind:'city',layers:[{name:'背景',path:'res://assets/scene/maps/backgrounds/main_city/maincity-background.jpg',speed:.1},{name:'中景',path:'res://assets/scene/maps/backgrounds/main_city/maincity-midground.png',speed:.5},{name:'前景',path:'res://assets/scene/maps/backgrounds/main_city/maincity-foreground.png',speed:1}],walkable:walk.points,spawn,portal:city.portal_trigger,effects:city.effects||[]}];
 for(const key of keys){const i=legacy.indexOf(key);maps.push({id:key,name:titles[key],kind:'dungeon',width:widths[key],height:1200,layers:[{name:'背景',path:layers+'tree-sea-shared-background.jpg',speed:.1},{name:'中景',path:layers+(key==='normal_1'?'tree-sea-normal-midground-1.png':key==='normal_2'?'tree-sea-normal-midground-2.png':`tree-sea-${key}-midground.png`),speed:.5},{name:'前景',path:layers+(key==='normal_1'?'tree-sea-normal-foreground-1.png':key==='normal_2'?'tree-sea-normal-foreground-2.png':`tree-sea-${key}-foreground.png`),speed:1}],walkable:dungeon.walkable_polygons_by_foreground?.[key]||dungeon.walkable_polygons?.[i]||defaults(widths[key]),spawn:dungeon.spawn_rects_by_foreground?.[key]||dungeon.spawn_rects?.[i],altar:dungeon.altar_tree_positions_by_foreground?.[key]||dungeon.altar_tree_positions?.[i],altarArea:dungeon.altar_trigger_polygons_by_foreground?.[key]||dungeon.altar_trigger_polygons?.[i],portals:(dungeon.portal_trigger_positions_by_foreground?.[key]||dungeon.portal_trigger_positions?.[i]||[]).map((position,n)=>({position,radius:(dungeon.portal_trigger_radii_by_foreground?.[key]||dungeon.portal_trigger_radii?.[i])[n],effect:(dungeon.portal_effect_positions_by_foreground?.[key]||dungeon.portal_effect_positions?.[i])[n]}))});}
 return {maps:clone(maps),revision:hash({city,projectDungeon,dungeon,walk,spawn}),city,dungeon};
}
function point(p,w,h){if(!Array.isArray(p)||p.length!==2)throw Error('坐标需要 X、Y 两个数字');number(p[0],'X',0,w);number(p[1],'Y',0,h);}
export function polygonArea(points){return Math.abs(points.reduce((sum,p,i)=>{const q=points[(i+1)%points.length];return sum+p[0]*q[1]-q[0]*p[1];},0))/2;}
export function inside(p,points){let result=false;for(let i=0,j=points.length-1;i<points.length;j=i++){const a=points[i],b=points[j];if(((a[1]>p[1])!==(b[1]>p[1]))&&(p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0]))result=!result;}return result;}
function polygon(points,w,h,min){if(!Array.isArray(points)||points.length<3||points.length>1000)throw Error('多边形至少需要 3 个顶点');for(const p of points)point(p,w,h);if(polygonArea(points)<min)throw Error(`区域面积不能小于 ${min} px²`);
 const cross=(a,b,c)=>(b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0]);
 for(let i=0;i<points.length;i++)for(let j=i+2;j<points.length;j++){if(i===0&&j===points.length-1)continue;const a=points[i],b=points[(i+1)%points.length],c=points[j],d=points[(j+1)%points.length];if(cross(a,b,c)*cross(a,b,d)<0&&cross(c,d,a)*cross(c,d,b)<0)throw Error('多边形边线不能交叉');}
}
export function validateMap(map){
 const w=map.id==='main-city-current'?5400:widths[map.id],h=1200;if(!w)throw Error('未知地图');
 const spawnMin=map.id==='main-city-current'?130:32;
 polygon(map.walkable,w,h,16900);point(map.spawn.position,w,h);point(map.spawn.size,w,h);if(map.spawn.size.some(n=>n<spawnMin)||map.spawn.position[0]+map.spawn.size[0]>w||map.spawn.position[1]+map.spawn.size[1]>h)throw Error(`出生区域必须在地图内，且宽高不小于 ${spawnMin} px`);
 const samples=[map.spawn.position,[map.spawn.position[0]+map.spawn.size[0],map.spawn.position[1]+map.spawn.size[1]],[map.spawn.position[0]+map.spawn.size[0]/2,map.spawn.position[1]+map.spawn.size[1]/2]];
 if(!samples.some(p=>inside(p,map.walkable)))throw Error('出生区域需要与可行走区相交');
 // Boss rooms retain the game's unused legacy portal anchors beyond the foreground's width.
 const anchorWidth=map.id==='boss'?5400:w;
 const ellipse=e=>{point(e.position,anchorWidth,h);if(!Array.isArray(e.radius)||e.radius.length!==2)throw Error('触发范围需要两个半径');e.radius.forEach(n=>number(n,'触发半径',1,600));};
 if(map.id==='main-city-current'){ellipse(map.portal);if(!Array.isArray(map.effects)||map.effects.length>50)throw Error('主城特效列表无效');for(const e of map.effects){if(e.type!=='main_city_teleport_yellow')throw Error('不支持的主城特效');point([e.x,e.y],w,h);number(e.scale,'特效缩放',0.01,10);number(e.rotation??0,'特效旋转',-360,360);}}
 else{point(map.altar,w,h);polygon(map.altarArea,w,h,1);if(!Array.isArray(map.portals)||map.portals.length!==3)throw Error('副本需要三个传送阵');for(const e of map.portals){ellipse(e);point(e.effect,anchorWidth,h);}}
 return map;
}
export async function saveMaps(input,root=gameRoot,runtime=userRoot){return locked(async()=>{
 const current=await readMaps(root,runtime);if(input.revision!==current.revision)throw Error('地图已在其他页面或游戏中更新，请重新读取后保存');if(!Array.isArray(input.maps))throw Error('地图数据无效');
 const city=clone(current.city),dungeon=clone(current.dungeon),ids=new Set();let cityChanged=false,dungeonChanged=false;
 for(const map of input.maps){validateMap(map);if(ids.has(map.id))throw Error('地图重复');ids.add(map.id);
  if(map.id==='main-city-current'){Object.assign(city,{walkable_area:{points:map.walkable},spawn_area:map.spawn,portal_trigger:map.portal,effects:map.effects});cityChanged=true;}
  else{dungeonChanged=true;const values={walkable_polygons:map.walkable,spawn_rects:map.spawn,altar_tree_positions:map.altar,altar_trigger_polygons:map.altarArea,portal_trigger_positions:map.portals.map(p=>p.position),portal_trigger_radii:map.portals.map(p=>p.radius),portal_effect_positions:map.portals.map(p=>p.effect)};
   for(const [field,value] of Object.entries(values)){dungeon[field+'_by_foreground']??={};dungeon[field+'_by_foreground'][map.id]=value;dungeon[field]??=Array(6).fill(null);for(let i=0;i<6;i++)if(legacy[i]===map.id)dungeon[field][i]=value;}
  }
 }
 const writes=[];if(cityChanged)writes.push([join(root,'config/main_city_editor.json'),city],[join(runtime,'city_walkable_area.json'),city.walkable_area],[join(runtime,'city_spawn_area.json'),city.spawn_area]);
 if(dungeonChanged)writes.push([join(root,'config/dungeon_area_editor.json'),dungeon],[join(runtime,'dungeon_area_editor.json'),dungeon]);
 await transaction(writes);const next=await readMaps(root,runtime);return {maps:next.maps,revision:next.revision};
});}
