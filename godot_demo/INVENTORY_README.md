# 背包系统

依据《主角背包系统_设计讨论_v0.1.md》的四组新增补充规则实现；与旧段落冲突时以补充规则为准。2026-09-19 确认初始容量 50 格。

## 当前行为

- 分类下拉：全部、通用、装备、任务、技能；打开时全部分类、滚动归零、无选中。
- 全部视图显示 50 个固定格位，移除后留空，新物品占第一个空格；分类视图只显示对应物品。
- 6 列，图标 100×100，可视 5.5 行。
- 装备和技能不叠加；其余同 ID 叠加至 999。品质由配置决定。满包整笔入包失败并提示空间不足。
- 整理作用于全部背包：宝箱、消耗品、装备、技能、任务、其他；再按品质降序、道具 ID 升序、装备唯一 ID 升序排列，合并并消除空隙。
- TIPS 紧贴背包右侧、顶部对齐，固定宽度、随内容适配高度，超出可用高度裁切，无滚动。点击外部/空格/滚动列表取消选中，点击当前物品保持打开。
- 数量 1 不标数字，数量大于 1 显示在图标右下角；不显示内部编号。
- 装备按钮直接替换对应部位；双槽固定优先槽位 1；旧装备回到新装备原格，满包也可替换。副本禁换装。属性对比：提升绿色、下降红色、新增蓝色。
- 技能和任务只有来源；宝箱只有使用；消耗品不在背包提供使用。材料/其他通用及装备可丢弃，选择数量后二次确认。
- 来源为预留接口，点击无动作。宝箱奖励系统未开放，使用按钮禁用。消耗品保留效果回调接口，具体药物及主 UI 快捷使用待配置。
- 按账号保存固定格位、唯一标识和装备栏，角色属性查询叠加已装备属性，不把装备加成重复写进基础属性。
- 同 ID 堆叠内单独记录 temporary_count，离开副本或重新登录时只清除临时数量。

正式 items 仍为空，不发放测试物品；装备卸下、商店出售、技能学习、任务提交没有在本次增加。

## 配置

`config/inventory.json`：capacity 为初始总格数，items 为以道具 ID 为键的定义表。

定义字段：name、icon、description、category（general/equipment/quest/skill）、type（material/consumable/chest/equipment/quest/skill）、type_name、quality（0–6）、quality_name（可选）、quality_color（颜色字符串，缺省使用七级品质色）。同 ID 统一读同一配置。

装备额外配置 equipment_slot（部位键），slot_count=2 表示双槽，stats 为属性字典；属性键与角色属性一致，例如 attack、defense、max_health。实例 attributes 叠加到装备基础属性。宝箱可填写 contents_description，技能可填写 skill_description。stack_limit 旧配置已不使用。

## 接口及存档

- add_item(id, count, properties)：原子入包，返回成功与否；失败发 rejected 信号。
- remove_item(uid, count)：扣除数量，数量不足不变。
- discard_item(uid, count)：附加可丢弃类型检查，UI 负责二次确认。
- equip_item(uid, in_dungeon)：替换装备并发 changed，缺少部位配置或副本中拒绝。
- stat_bonus(key)：已装备属性合计。
- organize()：全包固定顺序整理。
- use_consumable(uid, in_dungeon, apply_effect)：验证可用场景，效果回调成功才扣除；回调负责目标、上限和生命红条规则。
- settle_dungeon()：幂等清理临时数量。
- snapshot()/restore()：版本 2 保存 position、equipped；兼容旧版无 position 的顺序存档。

## 验证

`zsh godot_demo/tests/run_changed_tests.sh godot_demo/main.gd`

专项覆盖 999 堆叠、固定格位、满包原子失败及换装、双槽默认槽位、装备属性、整理、不可丢弃类型、临时数量和存档。游戏集成覆盖账号隔离、界面重开/筛选/滚动、装备持久化与属性加成；因涉及主场景和属性查询，运行游戏回归。
