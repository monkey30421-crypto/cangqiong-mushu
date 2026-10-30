# 动画资源约定

- 用户要求：所有动画默认使用原生 Spine 动画，只有用户明确单独要求某项例外时才使用其他动画形式。
- 游戏与 Web 编辑器共用 `SpineSkeletonDataResource`（`.tres`）及其 `.spine-json`、`.atlas` 和图集贴图。直接读取骨骼时间轴与事件，不烘焙为逐帧 PNG / 精灵表，也不根据图片帧推断事件。
- `godot_demo/assets/action_library/` 已停用，不重新建立该目录或恢复对旧烘焙动作库的依赖。
- 原生特效注册在 `godot_demo/config/spine_effects.json`；角色与怪物模型资源在 `config/characters.json`，动作映射分别在 `character_actions.json` 和 `monster_actions.json`。
- 背景、图标、阴影和静态模型贴图仍是普通图片；Spine 自身的 PNG 图集必须保留。既有单项例外遵循用户对该资源的明确要求。
