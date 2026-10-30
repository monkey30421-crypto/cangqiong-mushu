extends Node2D

const InventoryScript = preload("res://modules/inventory_service.gd")
const InventoryPanelScript = preload("res://ui/inventory_panel.gd")
var inventory := InventoryScript.new()
var inventory_panel: Panel
var inventory_loading := false
const GroundLootScript = preload("res://modules/ground_loot.gd")
var ground_loot := GroundLootScript.new()
const HitEffectsScript = preload("res://modules/hit_effects.gd")
var hit_effects := HitEffectsScript.new()
const SceneDepthScript = preload("res://modules/scene_depth.gd")
var scene_depth := SceneDepthScript.new()

const CharacterProfilesScript = preload("res://modules/character_profiles.gd")
var character_profiles := CharacterProfilesScript.new()
var character_profile_store := "res://config/characters.json"
const CharacterShadowsScript = preload("res://modules/character_shadows.gd")
var character_shadows := CharacterShadowsScript.new()
const MonsterActionsScript = preload("res://modules/monster_actions.gd")
var monster_actions := MonsterActionsScript.new()
const CityTrainingScript = preload("res://modules/city_training.gd")
var city_training := CityTrainingScript.new()

const CharacterActionsScript = preload("res://modules/character_actions.gd")
var character_actions := CharacterActionsScript.new()
var character_action_store := "res://config/character_actions.json"
var attack_action_id := 2001
var combo_next_action := 2001
const COMBO_INPUT_WINDOW := 0.3
var combo_input_remaining := 0.0
var current_attack_duration := ATTACK_DURATION
var trace_attack_motion := OS.get_cmdline_user_args().has("--trace-attack-motion")
const DamageReactionScript = preload("res://modules/damage_reaction.gd")
var damage_reaction := DamageReactionScript.new()
var hurt_remaining := 0.0
var is_walking := false


# Main coordinates scene flow; reusable business rules live in res://modules.
const AccountServiceScript = preload("res://modules/account_service.gd")
const CombatRulesScript = preload("res://modules/combat_rules.gd")
const DungeonRouteGeneratorScript = preload("res://modules/dungeon_route_generator.gd")
const MapGeometryScript = preload("res://modules/map_geometry.gd")
const CITY_WIDTH := 5400.0
const CITY_HEIGHT := 1200.0
const CITY_FOREGROUND_PARALLAX := 1.0
const CITY_MIDGROUND_PARALLAX := 0.5
const CITY_BACKGROUND_PARALLAX := 0.1
const DUNGEON_WIDTH := 5400.0
const DUNGEON_HEIGHT := 1200.0
const DUNGEON_FOREGROUND_PARALLAX := 1.0
const DUNGEON_MIDGROUND_PARALLAX := 0.5
const DUNGEON_BACKGROUND_PARALLAX := 0.1
const VIEW_WIDTH := 1800.0
const VIEW_HEIGHT := 750.0
const CITY_WALKABLE_TOP := 400.0
const CITY_WALKABLE_BOTTOM := 800.0
const PLAYER_SCREEN_BASELINE_Y := 550.0
const WALKABLE_MIN_AREA := 16900.0
const CITY_WALKABLE_DEBUG_FILL := Color(0.18, 0.9, 0.56, 0.14)
const CITY_WALKABLE_DEBUG_BORDER := Color(0.24, 1.0, 0.68, 0.96)
const CITY_WALKABLE_EDITOR_VERTEX_RADIUS := 14.0
const CITY_WALKABLE_EDITOR_EDGE_TOLERANCE := 18.0
const CITY_SPAWN_DEFAULT_RECT := Rect2(180.0, 500.0, 320.0, 180.0)
const SPAWN_DEBUG_FILL := Color(1.0, 0.52, 0.12, 0.18)
const SPAWN_DEBUG_BORDER := Color(1.0, 0.68, 0.2, 0.95)
const SPAWN_MIN_SIZE := Vector2(130.0, 130.0)
const SPAWN_PICK_TOLERANCE := 30.0
const SPAWN_DRAG_MOVE := 4
const CITY_WALKABLE_EDITOR_ENABLED := false
const CITY_SPAWN_EDITOR_ENABLED := false
const NO_POINTER := -2
const ROLE_NAME_MAX_BYTES := 18
const PLAYER_HORIZONTAL_MARGIN := 98.4375
const PORTAL := Vector2(5107.0, 800.0)
const CITY_PORTAL_TRIGGER_DEFAULT_RADIUS := Vector2(246.09375, 150.0)
const MOVE_SPEED := 365.625
const JUMP_HEIGHT := 140.0
const JUMP_DURATION := 0.6
const JUMP_APEX_HOLD := 0.2
const DODGE_DISTANCE := 200.0
const DODGE_SPEED := MOVE_SPEED * 1.5
const DODGE_VERTICAL_SPEED := MOVE_SPEED * 0.2
const DODGE_DURATION := DODGE_DISTANCE / DODGE_SPEED
const DODGE_CURVE_POWER := 1.5
const DODGE_COOLDOWN := 0.5
const GETUP_ROLL_DISTANCE := 300.0
const GETUP_ROLL_DURATION := 0.55
const GETUP_ROLL_CURVE_POWER := 1.5
const JOYSTICK_CENTER := Vector2(73.0, 69.0)
const JOYSTICK_RADIUS := 45.0
# All world, camera, UI, and draw coordinates directly use the 1800×750 canvas.
const PLAYER_FRAME_CELL := 512
const PLAYER_FRAME_BASELINE := 400.0
const PLAYER_SCALE := 1.0
const STAND_FRAME_COUNT := 60
const RUN_FRAME_COUNT := 18
const ATTACK_FRAME_COUNT := 25
const ANIMATION_FPS := 30.0
const ATTACK_FPS := ANIMATION_FPS
const ATTACK_DURATION := ATTACK_FRAME_COUNT / ATTACK_FPS
const ATTACK_BEHIND_TOLERANCE := -42.1875
const DAMAGE_FLOATER_DURATION := 0.85
const DAMAGE_FLOATER_RISE := 82.0
const DUNGEON_PLAYER_SPAWN := Vector2(320.0, 650.0)
const DUNGEON_SPAWN_DEFAULT_RECT := Rect2(220.0, 580.0, 200.0, 140.0)
const DUNGEON_WALKABLE_TOP := 430.0
const DUNGEON_WALKABLE_BOTTOM := 850.0
const DUNGEON_INTERACT_RANGE := 180.0
const DUNGEON_PORTAL_TRIGGER_DEFAULT_RADIUS := Vector2(210.0, 120.0)
const DUNGEON_PORTAL_TRIGGER_MIN_RADIUS := 40.0
const DUNGEON_PORTAL_TRIGGER_MAX_RADIUS := 600.0
const DUNGEON_EDITOR_VERTEX_RADIUS := 14.0
const DUNGEON_EDITOR_EDGE_TOLERANCE := 18.0
const DUNGEON_WALKABLE_MIN_AREA := 16900.0
const DUNGEON_ALTAR_TRIGGER_MIN_AREA := 2500.0
const DUNGEON_WALKABLE_DEBUG_FILL := Color(0.18, 0.9, 0.56, 0.14)
const DUNGEON_WALKABLE_DEBUG_BORDER := Color(0.24, 1.0, 0.68, 0.96)
const DUNGEON_ALTAR_DEBUG_FILL := Color(1.0, 0.62, 0.16, 0.18)
const DUNGEON_ALTAR_DEBUG_BORDER := Color(1.0, 0.75, 0.25, 0.98)
const WAVE_FADE_DURATION := 1.0
const NEXT_WAVE_DELAY := 3.0
const DUNGEON_PORTAL_POSITIONS := [
	Vector2(4660.0, 480.0),
	Vector2(5200.0, 650.0),
	Vector2(4660.0, 820.0),
]
const DUNGEON_ALTAR_POSITIONS := [
	Vector2(650.0, 500.0),
	Vector2(4050.0, 500.0),
	Vector2(4050.0, 500.0),
	Vector2(4050.0, 500.0),
	Vector2(4050.0, 500.0),
	Vector2(2700.0, 500.0),
]
const DUNGEON_SHARED_BACKGROUND: Texture2D = preload("res://assets/scene/maps/backgrounds/dungeon_floor1/layers/tree-sea-shared-background.jpg")
const DUNGEON_NORMAL_FOREGROUNDS: Array[Texture2D] = [
	preload("res://assets/scene/maps/backgrounds/dungeon_floor1/layers/tree-sea-normal-foreground-1.png"),
	preload("res://assets/scene/maps/backgrounds/dungeon_floor1/layers/tree-sea-normal-foreground-2.png"),
]
const DUNGEON_PORTAL_SPINE_DATA: SpineSkeletonDataResource = preload("res://assets/scene/effects/teleport/chuanson_fuben-data.tres")
const DUNGEON_NORMAL_MIDGROUNDS: Array[Texture2D] = [
	preload("res://assets/scene/maps/backgrounds/dungeon_floor1/layers/tree-sea-normal-midground-1.png"),
	preload("res://assets/scene/maps/backgrounds/dungeon_floor1/layers/tree-sea-normal-midground-2.png"),
	preload("res://assets/scene/maps/backgrounds/dungeon_floor1/layers/tree-sea-normal-midground-3.png"),
]
const DUNGEON_START_FOREGROUND: Texture2D = preload("res://assets/scene/maps/backgrounds/dungeon_floor1/layers/tree-sea-start-foreground.png")
const DUNGEON_START_MIDGROUND: Texture2D = preload("res://assets/scene/maps/backgrounds/dungeon_floor1/layers/tree-sea-start-midground.png")
const DUNGEON_BOSS_FOREGROUND: Texture2D = preload("res://assets/scene/maps/backgrounds/dungeon_floor1/layers/tree-sea-boss-foreground.png")
const DUNGEON_BOSS_MIDGROUND: Texture2D = preload("res://assets/scene/maps/backgrounds/dungeon_floor1/layers/tree-sea-boss-midground.png")
const DUNGEON_FOREGROUND_KEYS := ["start", "normal_1", "normal_2", "boss"]
# Spine tree bone (-15, 132) + attachment y=0.5, height=307.
# Align its canvas bottom-centre with the map editor saved position.
const ALTAR_TREE_SPINE_ANCHOR_OFFSET := Vector2(15.00003, -21.0)
const ALTAR_TREE_SPINE_DATA: SpineSkeletonDataResource = preload("res://assets/scene/effects/altar_tree/jitanshu_m-data.tres")
const ALTAR_TREE_ACTIVATE_DURATION := 1.7
const PORTAL_EFFECT_FRAME_CELL := 512
const PORTAL_EFFECT_COLUMNS := 5
const PORTAL_EFFECT_FRAME_COUNT := 20
const PORTAL_EFFECT_FPS := PORTAL_EFFECT_FRAME_COUNT / 5.18
const PORTAL_EFFECT_SHEET: Texture2D = preload("res://assets/scene/effects/vfx/main-city-teleport-yellow-sheet.png")
const SMALL_MONSTER: Texture2D = preload("res://assets/character/art/monsters/gray-sprout-beast.png")
const LARGE_MONSTER: Texture2D = preload("res://assets/character/art/monsters/gray-shell-branch-beast.png")
const STATUS_AREA_CITY := "初枝集"
const STATUS_AREA_DUNGEON := "年轮树海"
const PLAYER_ATTRIBUTE_DEFS := [
	{"key": "race", "label": "种族"},
	{"key": "level", "label": "等级"},
	{"key": "experience", "label": "经验值"},
	{"key": "max_health", "label": "最大生命"},
	{"key": "max_mana", "label": "灵蕴上限"},
	{"key": "mana_regen", "label": "灵蕴自然恢复"},
	{"key": "mana_absorb", "label": "灵蕴吸收"},
	{"key": "attack", "label": "攻击力"},
	{"key": "defense", "label": "防御力"},
	{"key": "attack_speed", "label": "攻击速度"},
	{"key": "move_speed", "label": "移动速度"},
	{"key": "crit_rate", "label": "暴击率"},
	{"key": "crit_damage", "label": "暴击伤害"},
	{"key": "skill_haste", "label": "技能急速"},
	{"key": "healing_power", "label": "治疗效果"},
	{"key": "life_steal", "label": "吸血"},
]
const PLAYER_DEFAULT_STATS := {
	"race": "人族",
	"level": 1,
	"experience": 0,
	"max_health": 100,
	"max_mana": 100,
	"mana_regen": 1.0,
	"mana_absorb": 2.0,
	"attack": 10,
	"defense": 10,
	"attack_speed": 2.0,
	"move_speed": 100.0,
	"crit_rate": 5.0,
	"crit_damage": 150.0,
	"skill_haste": 100.0,
	"healing_power": 100.0,
	"life_steal": 0.0,
}

@onready var traveler: SpineSprite = $Traveler
@onready var city_background: Node2D = $CityBackground
@onready var city_background_layer: Node2D = $CityBackground/BackgroundLayer
@onready var city_midground_layer: Node2D = $CityBackground/MidgroundLayer
@onready var city_foreground_layer: Node2D = $CityBackground/ForegroundLayer
@onready var portal_effect: AnimatedSprite2D = $CityBackground/ForegroundLayer/PortalEffect
@onready var dungeon_background: Node2D = $DungeonBackground
@onready var dungeon_scene: Sprite2D = $DungeonBackground/Scene
@onready var dungeon_midground: Sprite2D = $DungeonBackground/Midground
@onready var dungeon_foreground: Sprite2D = $DungeonBackground/Foreground
@onready var altar_tree: SpineSprite = $DungeonBackground/AltarTree
@onready var login_screen: Control = $UI/LoginScreen
@onready var account_name: LineEdit = $UI/LoginScreen/Card/Form/AccountName
@onready var password: LineEdit = $UI/LoginScreen/Card/Form/Password
@onready var login_button: Button = $UI/LoginScreen/Card/Form/LoginButton
@onready var login_status: Label = $UI/LoginScreen/Card/Form/Status
@onready var naming_screen: Control = $UI/NamingScreen
@onready var role_name_input: LineEdit = $UI/NamingScreen/Frame/NameInput
@onready var naming_warning: Label = $UI/NamingScreen/Frame/Warning
@onready var naming_confirm_button: Button = $UI/NamingScreen/Frame/ConfirmButton
@onready var game_hud: Control = $UI/GameHUD
@onready var player_name_label: Label = $UI/GameHUD/PlayerStatus/PlayerName
@onready var health_bar: ProgressBar = $UI/GameHUD/PlayerStatus/HealthBar
@onready var health_value_label: Label = $UI/GameHUD/PlayerStatus/HealthValue
@onready var mana_bar: ProgressBar = $UI/GameHUD/PlayerStatus/ManaBar
@onready var joystick: Control = $UI/GameHUD/Joystick
@onready var joystick_knob: Panel = $UI/GameHUD/Joystick/Knob
@onready var status_button: Button = $UI/GameHUD/StatusButton
@onready var backpack_button: Button = $UI/GameHUD/BackpackButton
@onready var attack_button: Button = $UI/GameHUD/ActionCluster/AttackButton
@onready var jump_button: Button = $UI/GameHUD/ActionCluster/JumpButton
@onready var dodge_button: Button = $UI/GameHUD/ActionCluster/DodgeButton
@onready var dungeon_menu_button: Button = $UI/GameHUD/DungeonMenuButton
@onready var interact_button: Button = $UI/GameHUD/InteractButton
@onready var skill_buttons: Array[Button] = [
	$UI/GameHUD/ActionCluster/Skill1Button,
	$UI/GameHUD/ActionCluster/Skill2Button,
	$UI/GameHUD/ActionCluster/Skill3Button,
	$UI/GameHUD/ActionCluster/Skill4Button,
]
@onready var modal_dim: ColorRect = $UI/GameHUD/ModalDim
@onready var modal: Panel = $UI/GameHUD/Modal
@onready var modal_title: Label = $UI/GameHUD/Modal/Title
@onready var modal_body: Label = $UI/GameHUD/Modal/Body
@onready var status_content: Control = $UI/GameHUD/Modal/StatusContent
@onready var status_preview_player: SpineSprite = $UI/GameHUD/Modal/StatusContent/PreviewFrame/PreviewPlayer
@onready var status_name_label: Label = $UI/GameHUD/Modal/StatusContent/PreviewFrame/NameLabel
@onready var status_summary_label: Label = $UI/GameHUD/Modal/StatusContent/PreviewFrame/SummaryLabel
@onready var status_left_attributes: Label = $UI/GameHUD/Modal/StatusContent/AttributesFrame/LeftAttributes
@onready var status_right_attributes: Label = $UI/GameHUD/Modal/StatusContent/AttributesFrame/RightAttributes
@onready var dungeon_selection_list: Control = $UI/GameHUD/Modal/DungeonSelectionList
@onready var dungeon_floor_one_button: Button = $UI/GameHUD/Modal/DungeonSelectionList/FloorOneButton
@onready var modal_close_button: Button = $UI/GameHUD/Modal/CloseButton
@onready var modal_primary_button: Button = $UI/GameHUD/Modal/PrimaryButton
@onready var modal_secondary_button: Button = $UI/GameHUD/Modal/SecondaryButton

var state := "login"
var role_name := ""
var player_stats: Dictionary = PLAYER_DEFAULT_STATS.duplicate(true)
var current_health := 100.0
var current_mana := 100.0
var player := Vector2(260.625, 645)
var camera_x := 0.0
var camera_y := 0.0
var dungeon_world_width := DUNGEON_WIDTH
var facing := 1.0
var is_moving := false
var is_jumping := false
var jump_elapsed := 0.0
# Runtime height above the ground in pixels; only the jump trajectory changes it.
var character_height_px := 0.0
var dodge_remaining := 0.0
var dodge_elapsed := 0.0
var dodge_direction := 1.0
var getup_roll_remaining := 0.0
var getup_remaining := 0.0
var getup_roll_elapsed := 0.0
var getup_roll_direction := 0.0
var getup_roll_facing := 1.0
var getup_roll_action_id := 1010
var getup_pending := false
var attack_cooldown := 0.0
var dodge_cooldown := 0.0
var attack_anim := 0.0
var clear_time := -1.0
var monsters: Array[Dictionary] = []
var damage_floaters: Array[Dictionary] = []
var pending_dungeon_experience := 0
var account_store := "user://accounts.json"
var city_editor_project_store := "res://config/main_city_editor.json"
var walkable_area_store := "user://city_walkable_area.json"
var spawn_area_store := "user://city_spawn_area.json"
var dungeon_area_store := "user://dungeon_area_editor.json"
var dungeon_area_project_store := "res://config/dungeon_area_editor.json"
var city_walkable_polygon := PackedVector2Array([
	Vector2(PLAYER_HORIZONTAL_MARGIN, CITY_WALKABLE_TOP),
	Vector2(CITY_WIDTH - PLAYER_HORIZONTAL_MARGIN, CITY_WALKABLE_TOP),
	Vector2(CITY_WIDTH - PLAYER_HORIZONTAL_MARGIN, CITY_WALKABLE_BOTTOM),
	Vector2(PLAYER_HORIZONTAL_MARGIN, CITY_WALKABLE_BOTTOM),
])
var city_spawn_rect := CITY_SPAWN_DEFAULT_RECT
var city_portal_trigger_position := PORTAL
var city_portal_trigger_radius := CITY_PORTAL_TRIGGER_DEFAULT_RADIUS
var city_effect_configs: Array = []
var city_effects_configured := false
var city_walkable_drag_vertex := -1
var city_walkable_drag_pointer := NO_POINTER
var spawn_drag_corner := -1
var spawn_drag_pointer := NO_POINTER
var spawn_drag_offset := Vector2.ZERO
var current_account_id := ""
var joystick_vector := Vector2.ZERO
var joystick_mouse_active := false
var joystick_touch_index := -1
var last_skill_index := 0
var role_name_editing := false
var account_service := AccountServiceScript.new()
var combat_rules := CombatRulesScript.new()
var dungeon_route_generator := DungeonRouteGeneratorScript.new()
var dungeon_rng := RandomNumberGenerator.new()
var dungeon_route_nodes: Dictionary = {}
var dungeon_columns: Array[Array] = []
var dungeon_current_node_id := ""
var dungeon_chosen_path: Array[String] = []
var dungeon_available_targets: Array[String] = []
var dungeon_stage := ""
var dungeon_wave := 0
var dungeon_wave_fade_timer := 0.0
var dungeon_next_wave_timer := 0.0
var dungeon_elite_weight := 0.0
var dungeon_mutation_weight := 0.0
var dungeon_success_pending := false
var modal_mode := ""
var dungeon_walkable_polygons: Array = []
var dungeon_walkable_by_foreground: Dictionary = {}
var dungeon_altar_trigger_polygons: Array = []
var dungeon_altar_tree_positions: Array = []
var dungeon_portal_trigger_positions: Array = []
var dungeon_portal_trigger_radii: Array = []
var dungeon_portal_effect_positions: Array = []
var dungeon_spawn_rects: Array = []
var dungeon_editor_drag_kind := ""
var dungeon_area_editor_enabled := false
var dungeon_editor_drag_vertex := -1
var dungeon_editor_drag_pointer := NO_POINTER
var dungeon_altar_tree_state := "locked"
var altar_tree_activation_elapsed := 0.0
var dungeon_altar_tree_activated_nodes: Dictionary = {}
var dungeon_altar_tree_talked_nodes: Dictionary = {}
var dungeon_portal_spine_effects: Array[SpineSprite] = []


func _ready() -> void:
	add_child(character_shadows)
	add_child(hit_effects)
	add_child(scene_depth)
	scene_depth.lower_effects.draw.connect(_draw_monster_effect_layer.bind("lower", scene_depth.lower_effects))
	scene_depth.upper_effects.draw.connect(_draw_monster_effect_layer.bind("upper", scene_depth.upper_effects))
	scene_depth.floating_text.draw.connect(_draw_damage_floater_layer)
	inventory.configure()
	inventory_panel = InventoryPanelScript.new()
	modal.add_child(inventory_panel)
	inventory_panel.setup(inventory)
	inventory_panel.closed.connect(_close_modal)
	inventory_panel.hide()
	inventory.changed.connect(_on_inventory_changed)
	get_tree().auto_accept_quit = false
	character_profiles.load_config(character_profile_store)
	monster_actions.load_config()
	monster_actions.attack_effect_hit.connect(_on_monster_effect_hit)
	_load_main_city_project_config()
	_load_city_walkable_area()
	_load_city_spawn_area()
	_load_dungeon_area_editor()
	_setup_player_animations()
	_setup_portal_effect()
	_setup_altar_tree_animations()
	_setup_dungeon_portal_spine_effects()
	login_button.pressed.connect(_login)
	account_name.text_submitted.connect(func(_text: String): password.grab_focus())
	password.text_submitted.connect(func(_text: String): _login())
	role_name_input.text_changed.connect(_on_role_name_changed)
	role_name_input.text_submitted.connect(func(_text: String): _confirm_role_name())
	naming_confirm_button.pressed.connect(_confirm_role_name)
	joystick.gui_input.connect(_on_joystick_gui_input)
	status_button.pressed.connect(_show_status_panel)
	backpack_button.pressed.connect(_show_backpack_panel)
	# Evaluate the combo window at press time, not after the player releases.
	attack_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	attack_button.pressed.connect(_primary_action)
	jump_button.pressed.connect(_jump)
	dodge_button.pressed.connect(_dodge)
	dungeon_menu_button.pressed.connect(_show_context_menu)
	interact_button.pressed.connect(_interact)
	for skill_index in range(skill_buttons.size()):
		skill_buttons[skill_index].pressed.connect(_on_skill_pressed.bind(skill_index + 1))
	modal_close_button.pressed.connect(_close_modal)
	modal_primary_button.pressed.connect(_on_modal_primary)
	modal_secondary_button.pressed.connect(_on_modal_secondary)
	dungeon_floor_one_button.pressed.connect(_select_dungeon_floor_one)
	modal_dim.gui_input.connect(_on_modal_dim_gui_input)
	account_name.grab_focus()
	var preview_args := OS.get_cmdline_user_args()
	if "--preview-city" in preview_args or "--preview-portal" in preview_args or "--preview-dungeon" in preview_args or "--preview-core" in preview_args:
		role_name = "刻轮者583104"
		player_stats = PLAYER_DEFAULT_STATS.duplicate(true)
		current_health = float(player_stats["max_health"])
		current_mana = float(player_stats["max_mana"])
		_refresh_resource_bars()
		login_screen.hide()
		game_hud.show()
		traveler.show()
		_enter_city(false)
		if "--preview-dungeon" in preview_args:
			_enter_dungeon()
			player = Vector2(914.0625, 645)
			facing = 1.0
			attack_anim = ATTACK_DURATION * 0.55
		elif "--preview-core" in preview_args:
			_enter_dungeon()
			player = Vector2(2784.375, 645)
			camera_x = dungeon_world_width - VIEW_WIDTH
		elif "--preview-portal" in preview_args:
			player = PORTAL - Vector2(182.8125, 0)
			camera_x = CITY_WIDTH - VIEW_WIDTH
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if state == "dungeon":
			inventory.settle_dungeon()
			pending_dungeon_experience = 0
			_save_current_player_profile()
		get_tree().quit()


func _process(delta: float) -> void:
	if state == "login" or state == "naming":
		character_shadows.hide()
		scene_depth.hide()
		queue_redraw()
		return

	hit_effects.advance(delta, Vector2(camera_x, camera_y))
	character_actions.poll(delta, attack_anim <= 0.0 and not character_actions.has_attack_tail() and dodge_remaining <= 0.0 and not is_jumping and not (state == "dungeon" and dungeon_stage == "dead"))
	damage_reaction.advance(delta)
	var player_delta := character_actions.consume_hit_stop(delta)
	if damage_reaction.knockback_remaining > 0.0:
		var knockback := damage_reaction.advance_knockback(player_delta)
		player.x += float(knockback.offset_x)
		character_height_px = float(knockback.height)
		_clamp_player_position()
	if getup_pending and damage_reaction.down_remaining <= 0.0 and damage_reaction.knockback_remaining <= 0.0 and dungeon_stage != "dead":
		getup_pending = false
		_begin_getup_roll()
		if getup_roll_remaining <= 0.0 and getup_remaining <= 0.0:
			damage_reaction.finish_getup()
	if getup_remaining > 0.0:
		getup_remaining = maxf(0.0, getup_remaining - player_delta)
		if getup_remaining <= 0.0:
			damage_reaction.finish_getup()
	combo_input_remaining = maxf(0.0, combo_input_remaining - delta)
	hurt_remaining = maxf(0.0, hurt_remaining - player_delta)
	if not (state == "dungeon" and dungeon_stage == "dead"):
		_regenerate_mana(delta)
	var dodge_before := dodge_remaining
	var trace_position := player
	_move_player(player_delta)
	if trace_attack_motion and (dodge_before > 0.0 or attack_anim > 0.0):
		print("ATTACK_MOTION ", JSON.stringify({"id": attack_action_id, "active": character_actions.active_id, "delta": player_delta, "from": str(trace_position), "to": str(player), "advance_elapsed": character_actions.advance_elapsed, "dodge": dodge_remaining, "remaining": attack_anim, "modal": modal.visible, "revision": character_actions.revision}))
	var action_delta := player_delta
	var serial_before_advance := character_actions.playback_serial
	character_actions.advance(action_delta, traveler.position, facing)
	if character_actions.playback_serial != serial_before_advance and attack_anim > 0.0:
		action_delta = 0.0
	attack_cooldown = maxf(0.0, attack_cooldown - player_delta)
	dodge_cooldown = maxf(0.0, dodge_cooldown - player_delta)
	var dodge_attack_ended := attack_action_id == 2005 and attack_anim > 0.0 and attack_anim <= action_delta
	attack_anim = maxf(0.0, attack_anim - action_delta)
	if dodge_attack_ended:
		is_moving = false
		hurt_remaining = 0.0
		character_actions.play(1001, true)

	if state == "city":
		_update_damage_floaters(delta)
		city_training.advance(delta, monsters, monster_actions, _clamp_point_to_city_walkable_area)
	elif state == "dungeon":
		_update_damage_floaters(delta)
		_update_dungeon(delta)
		if not modal.visible and dungeon_stage != "dead" and current_health > 0.0:
			ground_loot.advance(delta, player, inventory.collect_item)

	var width := CITY_WIDTH if state == "city" else dungeon_world_width
	var height := CITY_HEIGHT if state == "city" else DUNGEON_HEIGHT
	var target_camera := clampf(player.x - VIEW_WIDTH * 0.5, 0.0, maxf(0.0, width - VIEW_WIDTH))
	# The camera already uses physical pixels, so integer alignment is direct.
	camera_x = roundf(lerpf(camera_x, target_camera, 1.0 - pow(0.0003, delta)))
	camera_y = clampf(player.y - PLAYER_SCREEN_BASELINE_Y, 0.0, maxf(0.0, height - VIEW_HEIGHT))
	if state == "city":
		_update_city_parallax()
	else:
		_update_dungeon_parallax()
		_update_dungeon_altar_tree()
		_update_dungeon_portal_spine_effects()
	_update_interact_button()
	_update_traveler()
	character_actions.advance(0.0, traveler.position, facing)
	hit_effects.advance(0.0, Vector2(camera_x, camera_y))
	if modal.visible and status_content.visible:
		_refresh_status_panel()
	queue_redraw()


# The full-screen HUD receives GUI events first, so world editors inspect raw input.
# Events are consumed only after an editor handle or an editable edge is selected.
func _input(event: InputEvent) -> void:
	if modal.visible:
		return
	if state == "dungeon":
		if dungeon_area_editor_enabled:
			_handle_dungeon_area_editor_input(event)
		return
	if state != "city":
		return
	_handle_city_area_editor_input(event)


func _handle_city_area_editor_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var world_position: Vector2 = event.position + Vector2(camera_x, camera_y)
				if _is_in_city_portal_trigger(world_position):
					_show_dungeon_selection()
					get_viewport().set_input_as_handled()
				elif CITY_SPAWN_EDITOR_ENABLED and _try_start_spawn_drag(event.position, -1):
					get_viewport().set_input_as_handled()
				elif CITY_WALKABLE_EDITOR_ENABLED and _try_start_city_walkable_drag(event.position, -1):
					get_viewport().set_input_as_handled()
			elif city_walkable_drag_pointer == -1:
				_finish_city_walkable_drag()
				get_viewport().set_input_as_handled()
			elif spawn_drag_pointer == -1:
				_finish_spawn_drag()
				get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if CITY_WALKABLE_EDITOR_ENABLED and _try_delete_city_walkable_vertex(event.position):
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		if city_walkable_drag_pointer == -1:
			if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
				_drag_city_walkable_vertex(event.position)
			else:
				_finish_city_walkable_drag()
			get_viewport().set_input_as_handled()
		elif spawn_drag_pointer == -1:
			if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
				_drag_spawn_corner(event.position)
			else:
				_finish_spawn_drag()
			get_viewport().set_input_as_handled()
	elif CITY_SPAWN_EDITOR_ENABLED and event is InputEventScreenTouch:
		if event.pressed:
			if _try_start_spawn_drag(event.position, event.index):
				get_viewport().set_input_as_handled()
		elif spawn_drag_pointer == event.index:
			_finish_spawn_drag()
			get_viewport().set_input_as_handled()
	elif CITY_SPAWN_EDITOR_ENABLED and event is InputEventScreenDrag and spawn_drag_pointer == event.index:
		_drag_spawn_corner(event.position)
		get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_ESCAPE and modal.visible:
		_close_modal()
		return
	if modal.visible or city_walkable_drag_pointer != NO_POINTER or spawn_drag_corner >= 0 or dungeon_editor_drag_pointer != NO_POINTER:
		return
	if state == "naming":
		return
	if key.keycode == KEY_SPACE:
		_jump()
	elif key.keycode == KEY_K:
		_dodge()
	elif state in ["city", "dungeon"] and key.keycode == KEY_J:
		_attack()
	elif key.keycode == KEY_E:
		_interact()


func _login() -> void:
	var account := account_name.text.strip_edges()
	if account.is_empty():
		login_status.text = "账号不能为空。"
		return

	var accounts := _load_accounts()
	var id := _find_account_id(accounts, account)
	var record: Dictionary
	if not id.is_empty():
		record = _normalize_account_record(accounts[id], account)
		accounts[id] = record
		_save_accounts(accounts)
	else:
		id = _generate_account_id(accounts)
		record = _normalize_account_record({"account_name": account, "role_name": "", "character_creation_completed": false}, account)
		accounts[id] = record
		_save_accounts(accounts)

	current_account_id = id
	player_stats = _normalize_player_stats(record.get("player_stats", {}))
	inventory_loading = true
	inventory.restore(record.get("inventory", {}))
	inventory_loading = false
	record["inventory"] = inventory.snapshot()
	accounts[id] = record
	_save_accounts(accounts)
	current_health = float(player_stats["max_health"])
	current_mana = float(player_stats["max_mana"])
	_refresh_resource_bars()
	var stored_role_name := str(record.get("role_name", ""))
	if stored_role_name.is_empty():
		_show_naming_screen()
		return
	_enter_game_with_role(stored_role_name)


func _show_naming_screen() -> void:
	state = "naming"
	login_screen.hide()
	naming_screen.show()
	game_hud.hide()
	traveler.hide()
	role_name_input.clear()
	naming_warning.text = ""
	role_name_input.call_deferred("grab_focus")


func _enter_game_with_role(confirmed_role_name: String) -> void:
	role_name = confirmed_role_name
	login_screen.hide()
	naming_screen.hide()
	game_hud.show()
	traveler.show()
	_refresh_resource_bars()
	_enter_city(false)


func _on_role_name_changed(value: String) -> void:
	if role_name_editing:
		return
	var limited := _truncate_role_name(value)
	if limited != value:
		role_name_editing = true
		role_name_input.text = limited
		role_name_input.caret_column = limited.length()
		role_name_editing = false
	naming_warning.text = ""


func _truncate_role_name(value: String) -> String:
	return account_service.truncate_role_name(value, ROLE_NAME_MAX_BYTES)


func _contains_emoji(value: String) -> bool:
	return account_service.contains_emoji(value)


func _is_role_name_legal(value: String) -> bool:
	return account_service.is_role_name_legal(value)


func _is_role_name_used(accounts: Dictionary, candidate: String) -> bool:
	return account_service.is_role_name_used(accounts, candidate, current_account_id)


func _confirm_role_name() -> void:
	if state != "naming":
		return
	var candidate := role_name_input.text
	if candidate.is_empty():
		naming_warning.text = "名字不能为空"
		return
	if candidate.to_utf8_buffer().size() > ROLE_NAME_MAX_BYTES or not _is_role_name_legal(candidate):
		naming_warning.text = "使用非法字符"
		return
	var accounts := _load_accounts()
	if _is_role_name_used(accounts, candidate):
		naming_warning.text = "已有相同名字"
		return
	if not accounts.has(current_account_id):
		return
	var record: Dictionary = accounts[current_account_id]
	record["role_name"] = candidate
	record["character_creation_completed"] = true
	record["player_stats"] = _normalize_player_stats(record.get("player_stats", {}))
	accounts[current_account_id] = record
	_save_accounts(accounts)
	_enter_game_with_role(candidate)


func _load_accounts() -> Dictionary:
	return account_service.load_accounts(account_store)


func _save_accounts(accounts: Dictionary) -> void:
	account_service.save_accounts(account_store, accounts)


func _normalize_account_record(record: Dictionary, account_name_value: String) -> Dictionary:
	return account_service.normalize_account_record(record, account_name_value, PLAYER_DEFAULT_STATS)


func _normalize_player_stats(raw_stats: Variant) -> Dictionary:
	return account_service.normalize_player_stats(raw_stats, PLAYER_DEFAULT_STATS)


func _save_current_player_profile() -> void:
	if current_account_id.is_empty():
		return
	var accounts := _load_accounts()
	if not accounts.has(current_account_id):
		return
	var record: Dictionary = _normalize_account_record(accounts[current_account_id], str(accounts[current_account_id].get("account_name", "")))
	record["role_name"] = role_name
	record["character_creation_completed"] = not role_name.is_empty()
	record["player_stats"] = _normalize_player_stats(player_stats)
	record["inventory"] = inventory.snapshot()
	accounts[current_account_id] = record
	_save_accounts(accounts)


func _get_player_stat(stat_key: String) -> Variant:
	var base = player_stats.get(stat_key, PLAYER_DEFAULT_STATS.get(stat_key))
	if base is float or base is int:
		return base + inventory.stat_bonus(str(stat_key))
	return base


func _refresh_resource_bars() -> void:
	var max_health_value := float(_get_player_stat("max_health"))
	var max_mana_value := float(_get_player_stat("max_mana"))
	current_health = clampf(current_health, 0.0, max_health_value)
	current_mana = clampf(current_mana, 0.0, max_mana_value)
	if is_instance_valid(health_bar):
		health_bar.max_value = max_health_value
		health_bar.value = current_health
	if is_instance_valid(health_value_label):
		health_value_label.text = "%d / %d" % [int(roundf(current_health)), int(roundf(max_health_value))]
	if is_instance_valid(mana_bar):
		mana_bar.max_value = max_mana_value
		mana_bar.value = current_mana


func _restore_player_resources() -> void:
	current_health = float(_get_player_stat("max_health"))
	current_mana = float(_get_player_stat("max_mana"))
	_refresh_resource_bars()


func _regenerate_mana(delta: float) -> void:
	if current_mana >= float(_get_player_stat("max_mana")):
		return
	current_mana = minf(float(_get_player_stat("max_mana")), current_mana + float(_get_player_stat("mana_regen")) * delta)
	_refresh_resource_bars()


func _effective_move_speed() -> float:
	return MOVE_SPEED * float(_get_player_stat("move_speed")) / 100.0


func _attack_interval() -> float:
	return 1.0 / maxf(float(_get_player_stat("attack_speed")), 0.01)


func _roll_crit() -> bool:
	return combat_rules.roll_crit(float(_get_player_stat("crit_rate")))


func _compute_damage(attack_value: float, target_defense: float, allow_crit: bool) -> Dictionary:
	return combat_rules.compute_damage(
		attack_value,
		target_defense,
		allow_crit,
		float(_get_player_stat("crit_rate")),
		float(_get_player_stat("crit_damage"))
	)


func _apply_life_steal_and_mana_absorb(actual_damage: int, can_life_steal: bool) -> void:
	if actual_damage <= 0:
		return
	current_mana = minf(float(_get_player_stat("max_mana")), current_mana + actual_damage * float(_get_player_stat("mana_absorb")) / 100.0)
	if can_life_steal and float(_get_player_stat("life_steal")) > 0.0:
		current_health = minf(float(_get_player_stat("max_health")), current_health + actual_damage * float(_get_player_stat("life_steal")) / 100.0)
	_refresh_resource_bars()


func _monster_definition(kind: int, position: Vector2, display_name: String, phase: float, experience_reward: int) -> Dictionary:
	var monster: Dictionary = combat_rules.monster_definition(kind, position, display_name, phase, experience_reward, VIEW_WIDTH)
	var monster_type: String = ["normal", "elite", "mutation", "boss"][kind]
	var character_id := character_profiles.character_id_for_type(monster_type)
	if character_id < 101:
		push_error("缺少怪物类型配置：%s" % monster_type)
		return monster
	character_profiles.configure_monster(monster, character_id)
	monster_actions.play(monster, "idle")
	return monster


func _current_area_name() -> String:
	if state == "city":
		return STATUS_AREA_CITY
	if state == "dungeon" and not dungeon_current_node_id.is_empty():
		return "%s · %s" % [STATUS_AREA_DUNGEON, dungeon_current_node_id]
	return STATUS_AREA_DUNGEON


func _format_status_attribute(stat_key: String, value: Variant) -> String:
	match stat_key:
		"race":
			return str(value)
		"level":
			return "%d级" % int(value)
		"experience":
			return str(int(value))
		"max_health", "max_mana", "attack", "defense":
			return str(int(value))
		"mana_regen":
			return "%d点/秒" % int(roundf(float(value)))
		"attack_speed":
			return "%.2f次/秒" % float(value)
		"mana_absorb", "move_speed", "crit_rate", "crit_damage", "skill_haste", "healing_power", "life_steal":
			return "%.2f%%" % float(value)
	return str(value)


func _build_status_attribute_columns() -> Dictionary:
	var left_lines: Array[String] = []
	var right_lines: Array[String] = []
	for attribute_index in range(PLAYER_ATTRIBUTE_DEFS.size()):
		var attribute: Dictionary = PLAYER_ATTRIBUTE_DEFS[attribute_index]
		var text := "%s：%s" % [
			str(attribute.label),
			_format_status_attribute(str(attribute.key), _get_player_stat(str(attribute.key))),
		]
		if attribute_index < PLAYER_ATTRIBUTE_DEFS.size() / 2:
			left_lines.append(text)
		else:
			right_lines.append(text)
	return {"left": "\n".join(left_lines), "right": "\n".join(right_lines)}


func _refresh_status_panel() -> void:
	status_name_label.text = role_name
	status_summary_label.text = "区域：%s\n生命：%d / %d\n灵蕴：%d / %d" % [
		_current_area_name(),
		int(roundf(current_health)),
		int(_get_player_stat("max_health")),
		int(roundf(current_mana)),
		int(_get_player_stat("max_mana")),
	]
	var columns := _build_status_attribute_columns()
	status_left_attributes.text = str(columns.left)
	status_right_attributes.text = str(columns.right)
	status_preview_player.get_animation_state().set_animation(&"idle_SingleWeapon", true, 0)


func _find_account_id(accounts: Dictionary, account: String) -> String:
	return account_service.find_account_id(accounts, account)


func _generate_account_id(accounts: Dictionary) -> String:
	return account_service.generate_account_id(accounts)


func _generate_dungeon_route() -> void:
	var generated: Dictionary = dungeon_route_generator.generate(dungeon_rng)
	dungeon_route_nodes = generated.nodes
	dungeon_columns = generated.columns
	dungeon_elite_weight = float(generated.elite_weight)
	dungeon_mutation_weight = float(generated.mutation_weight)
	dungeon_chosen_path.clear()
	dungeon_available_targets.clear()
	dungeon_current_node_id = "2A"
	dungeon_chosen_path.append(dungeon_current_node_id)


func _load_dungeon_node(node_id: String) -> void:
	hit_effects.clear()
	monster_actions.clear()
	ground_loot.clear()
	hurt_remaining = 0.0
	damage_reaction.reset()
	combo_input_remaining = 0.0
	getup_roll_remaining = 0.0
	getup_remaining = 0.0
	getup_pending = false
	getup_roll_elapsed = 0.0
	getup_roll_direction = 0.0
	character_height_px = 0.0
	character_actions.clear_effects()
	dungeon_current_node_id = node_id
	if node_id not in dungeon_chosen_path:
		dungeon_chosen_path.append(node_id)
	dungeon_available_targets.clear()
	var node: Dictionary = dungeon_route_nodes[node_id]
	node["revealed"] = true
	dungeon_route_nodes[node_id] = node
	_set_dungeon_visual_layers(str(node["type"]), int(node["map"]))
	_reset_dungeon_altar_tree_for_current_node()
	player = _random_dungeon_spawn_point()
	_clamp_player_position()
	camera_x = 0.0
	camera_y = clampf(player.y - PLAYER_SCREEN_BASELINE_Y, 0.0, maxf(0.0, DUNGEON_HEIGHT - VIEW_HEIGHT))
	_update_dungeon_parallax()
	monsters.clear()
	dungeon_wave = 0
	dungeon_wave_fade_timer = 0.0
	dungeon_next_wave_timer = 0.0
	attack_anim = 0.0
	attack_cooldown = 0.0
	if str(node["type"]) == "start":
		dungeon_stage = "await_altar"
	elif str(node["type"]) == "boss":
		_spawn_dungeon_wave(1)
	else:
		_spawn_dungeon_wave(1)
	queue_redraw()


func _set_dungeon_visual_layers(area_type: String, map_number: int) -> void:
	dungeon_scene.texture = DUNGEON_SHARED_BACKGROUND
	_configure_dungeon_layer(dungeon_scene, DUNGEON_SHARED_BACKGROUND)
	if area_type == "start":
		_configure_dungeon_layer(dungeon_midground, DUNGEON_START_MIDGROUND)
		_configure_dungeon_layer(dungeon_foreground, DUNGEON_START_FOREGROUND)
	elif area_type == "boss":
		_configure_dungeon_layer(dungeon_midground, DUNGEON_BOSS_MIDGROUND)
		_configure_dungeon_layer(dungeon_foreground, DUNGEON_BOSS_FOREGROUND)
	else:
		var variant_index := maxi(map_number - 2, 0)
		_configure_dungeon_layer(dungeon_midground, DUNGEON_NORMAL_MIDGROUNDS[variant_index % DUNGEON_NORMAL_MIDGROUNDS.size()])
		_configure_dungeon_layer(dungeon_foreground, DUNGEON_NORMAL_FOREGROUNDS[variant_index % DUNGEON_NORMAL_FOREGROUNDS.size()])
	dungeon_world_width = dungeon_foreground.texture.get_size().x


func _update_dungeon_parallax() -> void:
	# The foreground defines the playable width.  Midground and background are
	# visual-only layers and scroll at the same 50% / 10% rates as the city.
	dungeon_background.position = Vector2(0.0, -camera_y)
	dungeon_foreground.position.x = dungeon_foreground.texture.get_size().x * 0.5 - camera_x * DUNGEON_FOREGROUND_PARALLAX
	dungeon_midground.position.x = dungeon_midground.texture.get_size().x * 0.5 - camera_x * DUNGEON_MIDGROUND_PARALLAX
	dungeon_scene.position.x = dungeon_scene.texture.get_size().x * 0.5 - camera_x * DUNGEON_BACKGROUND_PARALLAX


func _setup_dungeon_portal_spine_effects() -> void:
	for portal_index in range(DUNGEON_PORTAL_POSITIONS.size()):
		var portal_effect := SpineSprite.new()
		portal_effect.name = "DungeonPortalSpine%d" % portal_index
		portal_effect.skeleton_data_res = DUNGEON_PORTAL_SPINE_DATA
		SceneDepthScript.set_layer(portal_effect, SceneDepthScript.LOWER_EFFECT_Z)
		portal_effect.hide()
		dungeon_background.add_child(portal_effect)
		dungeon_portal_spine_effects.append(portal_effect)


func _dungeon_portal_spine_animation_for_type(area_type: String) -> String:
	match area_type:
		"normal":
			return "1"
		"elite":
			return "2"
		"mutation":
			return "3"
		"boss":
			return "4"
		_:
			return ""


func _update_dungeon_portal_spine_effects() -> void:
	if dungeon_portal_spine_effects.is_empty():
		return
	var portal_animations: Dictionary = {}
	if state == "dungeon" and dungeon_stage == "portals":
		for target_id in dungeon_available_targets:
			var target: Dictionary = dungeon_route_nodes.get(target_id, {})
			var animation_name := _dungeon_portal_spine_animation_for_type(str(target.get("type", "")))
			if not animation_name.is_empty():
				portal_animations[_portal_index_for_target(target_id)] = animation_name
	for portal_index in range(dungeon_portal_spine_effects.size()):
		var portal_effect := dungeon_portal_spine_effects[portal_index]
		var animation_name: String = portal_animations.get(portal_index, "")
		portal_effect.visible = not animation_name.is_empty()
		if not portal_effect.visible:
			continue
		var portal_position := _current_dungeon_portal_effect_position(portal_index)
		# Portal effects belong to the foreground coordinate system and therefore
		# follow the gameplay camera at 100%.
		portal_effect.position = Vector2(portal_position.x - camera_x, portal_position.y)
		if str(portal_effect.get_meta("animation_name", "")) != animation_name:
			portal_effect.get_animation_state().set_animation(animation_name, true, 0)
			portal_effect.set_meta("animation_name", animation_name)


func _current_dungeon_altar_tree_position() -> Vector2:
	var map_number := _current_dungeon_map_number()
	if map_number <= 0 or map_number > dungeon_altar_tree_positions.size():
		return DUNGEON_ALTAR_POSITIONS[0]
	return dungeon_altar_tree_positions[map_number - 1]


func _reset_dungeon_altar_tree_for_current_node() -> void:
	if dungeon_current_node_id.is_empty():
		return
	if dungeon_altar_tree_talked_nodes.get(dungeon_current_node_id, false):
		dungeon_altar_tree_state = "talked"
		_play_altar_tree(&"talked")
	elif dungeon_altar_tree_activated_nodes.get(dungeon_current_node_id, false):
		dungeon_altar_tree_state = "ready"
		_play_altar_tree(&"ready")
	else:
		dungeon_altar_tree_state = "locked"
		_play_altar_tree(&"locked")


func _is_current_altar_tree_in_view() -> bool:
	var position := _current_dungeon_altar_tree_position()
	return position.x >= camera_x - 200.0 and position.x <= camera_x + VIEW_WIDTH + 200.0 and position.y >= camera_y - 200.0 and position.y <= camera_y + VIEW_HEIGHT + 200.0


func _update_dungeon_altar_tree() -> void:
	if not is_instance_valid(altar_tree):
		return
	altar_tree.visible = state == "dungeon" and not dungeon_current_node_id.is_empty()
	if not altar_tree.visible:
		return
	var tree_position := _current_dungeon_altar_tree_position()
	# The tree belongs to the foreground coordinate system, so it follows the camera at 100%.
	altar_tree.position = Vector2(tree_position.x - camera_x, tree_position.y) + ALTAR_TREE_SPINE_ANCHOR_OFFSET
	if dungeon_altar_tree_state == "activating":
		altar_tree_activation_elapsed += get_process_delta_time()
		if altar_tree_activation_elapsed >= ALTAR_TREE_ACTIVATE_DURATION:
			_on_altar_tree_animation_finished()
	if dungeon_stage == "await_altar" and dungeon_altar_tree_state == "locked" and _is_current_altar_tree_in_view():
		dungeon_altar_tree_activated_nodes[dungeon_current_node_id] = true
		dungeon_altar_tree_state = "activating"
		altar_tree_activation_elapsed = 0.0
		_play_altar_tree(&"activate")


func _play_altar_tree(animation_name: StringName) -> void:
	if not is_instance_valid(altar_tree) or altar_tree.skeleton_data_res == null:
		return
	var source_animation := StringName({"locked": "1", "activate": "2", "ready": "3", "talked": "4"}.get(String(animation_name), "1"))
	altar_tree.get_animation_state().set_animation(source_animation, source_animation != &"2", 0)


func _on_altar_tree_animation_finished() -> void:
	if dungeon_altar_tree_state == "activating":
		dungeon_altar_tree_state = "ready"
		_play_altar_tree(&"ready")


func _configure_dungeon_layer(layer: Sprite2D, texture: Texture2D) -> void:
	layer.texture = texture
	var texture_size := texture.get_size()
	# 所有资源均从世界左边缘原生对齐，起点和首领图不会被拉伸到 5400 宽。
	layer.position = Vector2(texture_size.x * 0.5, DUNGEON_HEIGHT * 0.5)
	layer.region_enabled = true
	layer.region_rect = Rect2(0, 400, texture_size.x, DUNGEON_HEIGHT)


func _spawn_dungeon_wave(wave_number: int) -> void:
	dungeon_wave = wave_number
	monsters.clear()
	var node: Dictionary = dungeon_route_nodes[dungeon_current_node_id]
	var area_type := str(node["type"])
	var monster_kinds: Array[int] = []
	if area_type == "boss":
		monster_kinds.append(3)
	elif area_type == "normal":
		for _index in range(dungeon_rng.randi_range(10, 20)):
			monster_kinds.append(0)
	elif area_type == "elite":
		var total := dungeon_rng.randi_range(15, 20)
		var elite_count := floori(total * 0.4)
		for index in range(total):
			monster_kinds.append(1 if index < elite_count else 0)
	else:
		for _index in range(dungeon_rng.randi_range(5, 10)):
			monster_kinds.append(2)
	_shuffle_with_dungeon_rng(monster_kinds)
	var spawn_positions := _dungeon_spawn_positions(monster_kinds.size(), area_type == "boss")
	for monster_index in range(monster_kinds.size()):
		var kind := monster_kinds[monster_index]
		var display_name: String = ["灰蚀芽兽", "灰壳精英", "灰蚀变异体", "灰冠枝王"][kind]
		var reward: int = [2, 5, 8, 50][kind]
		var spawn_position := _clamp_point_to_dungeon_walkable_area(spawn_positions[monster_index])
		monsters.append(_monster_definition(kind, spawn_position, display_name, dungeon_rng.randf_range(0.0, TAU), reward))
	dungeon_wave_fade_timer = WAVE_FADE_DURATION
	dungeon_stage = "spawning"


func _shuffle_with_dungeon_rng(values: Array) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := dungeon_rng.randi_range(0, index)
		var value: Variant = values[index]
		values[index] = values[swap_index]
		values[swap_index] = value


func _dungeon_spawn_positions(count: int, boss_only: bool) -> Array[Vector2]:
	if boss_only:
		return [Vector2(3150.0, 650.0)]
	var candidates: Array[Vector2] = []
	for y_value in [500.0, 675.0, 850.0]:
		for x_value in range(900, 4901, 260):
			candidates.append(Vector2(float(x_value), y_value))
	_shuffle_with_dungeon_rng(candidates)
	return candidates.slice(0, count)


func _update_dungeon(delta: float) -> void:
	monster_actions.advance_corpses(delta, _clamp_point_to_dungeon_walkable_area)
	for monster in monsters:
		monster_actions.advance_reaction(monster, delta, _clamp_point_to_dungeon_walkable_area)
	for index in range(monsters.size() - 1, -1, -1):
		if monsters[index].hp <= 0 and float(monsters[index].get("hit_stop_remaining", 0.0)) <= 0.0:
			_defeat_monster(monsters[index])
	match dungeon_stage:
		"spawning":
			dungeon_wave_fade_timer = maxf(0.0, dungeon_wave_fade_timer - delta)
			var alpha := 1.0 - dungeon_wave_fade_timer / WAVE_FADE_DURATION
			for monster in monsters:
				monster["spawn_alpha"] = alpha
			if dungeon_wave_fade_timer <= 0.0:
				for monster in monsters:
					monster["active"] = true
					monster["spawn_alpha"] = 1.0
				dungeon_stage = "combat"
		"combat":
			_update_monster_ai(delta)
			if monsters.is_empty():
				var area_type := str(dungeon_route_nodes[dungeon_current_node_id]["type"])
				if area_type == "boss" or dungeon_wave >= 2:
					dungeon_stage = "await_altar"
				else:
					dungeon_stage = "wave_delay"
					dungeon_next_wave_timer = NEXT_WAVE_DELAY
		"wave_delay":
			dungeon_next_wave_timer = maxf(0.0, dungeon_next_wave_timer - delta)
			if dungeon_next_wave_timer <= 0.0:
				_spawn_dungeon_wave(2)
	for monster in monsters:
		monster_actions.advance(monster, 0.0)
	for monster in monsters + monster_actions.corpses:
		monster_actions.prepare_native_sprite(self, monster)


func _update_monster_ai(delta: float) -> void:
	if modal.visible or dungeon_stage != "combat":
		return
	for monster in monsters:
		monster.moving = false
		if not bool(monster["active"]) or float(monster.get("hit_stop_remaining", 0.0)) > 0.0 or int(monster.hp) <= 0:
			continue
		if monster.has("damage_reaction") and (monster.damage_reaction.down_remaining > 0.0 or monster.damage_reaction.is_pushed()):
			continue
		if float(monster.get("hit", 0.0)) > 0.0:
			continue
		monster["attack_cooldown"] = maxf(0.0, float(monster["attack_cooldown"]) - delta)
		if monster_actions.busy(monster):
			continue
		var offset: Vector2 = player - Vector2(monster["pos"])
		if absf(offset.x) > 0.1:
			monster.facing = signf(offset.x)
		if not bool(monster["engaged"]) and offset.length() <= float(monster["alert_range"]):
			monster["engaged"] = true
		if not bool(monster["engaged"]):
			continue
		if absf(offset.x) > float(monster["attack_range_x"]) + float(character_profiles.profile(1).x) * 0.5 or absf(offset.y) > float(monster["attack_range_y"]):
			var previous_position := Vector2(monster["pos"])
			var step := offset.normalized() * float(monster["move_speed"]) * delta
			monster["pos"] = Vector2(monster["pos"]) + step
			monster["pos"] = _clamp_point_to_dungeon_walkable_area(Vector2(monster["pos"]))
			monster_actions.update_movement(monster, player, Vector2(monster["pos"]) - previous_position)
		elif float(monster["attack_cooldown"]) <= 0.0 and combat_rules.overlaps_hurtbox(offset, character_height_px, float(monster.get("character_height_px", 0.0)), float(monster["attack_range_x"]), float(monster["attack_range_y"]), float(monster.get("attack_range_height", 0.0)), float(character_profiles.profile(1).x), float(character_profiles.profile(1).h)):
			monster["attack_cooldown"] = 1.0 / maxf(float(monster["attack_speed"]), 0.01)
			monster_actions.play(monster, monster_actions.choose_attack(monster), true)
			monster_actions.advance(monster, 0.0)

func _on_monster_effect_hit(monster: Dictionary, attack: Dictionary, hit_targets: Array, contact_area: Rect2 = Rect2()) -> void:
	if state != "dungeon" or dungeon_stage != "combat" or modal.visible or hit_targets.has(1):
		return
	if not monsters.has(monster) or not bool(monster.get("active", false)) or int(monster.get("hp", 0)) <= 0 or float(monster.get("hit", 0.0)) > 0.0 or float(monster.get("hit_stop_remaining", 0.0)) > 0.0:
		return
	if monster.has("damage_reaction") and monster.damage_reaction.down_remaining > 0.0:
		return
	var offset := player - Vector2(monster.pos)
	var profile: Dictionary = character_profiles.profile(1)
	if float(attack.attack) <= 0.0 or float(attack.range_x) <= 0.0 or not combat_rules.overlaps_hurtbox(offset, character_height_px, float(monster.get("character_height_px", 0.0)), float(attack.range_x), float(attack.range_y), float(attack.range_h), float(profile.x), float(profile.h)):
		return
	var direction := float(monster.get("facing", 1.0))
	if offset.x * direction + float(profile.x) * 0.5 <= ATTACK_BEHIND_TOLERANCE:
		return
	var health_before := current_health
	var damage: int = int(_compute_damage(float(attack.attack), float(_get_player_stat("defense")), false).damage)
	var target_origin := player - Vector2(0.0, character_height_px)
	var attacker_origin := Vector2(monster.pos) - Vector2(0.0, float(monster.get("character_height_px", 0.0)))
	var contact := HitEffectsScript.contact_point(attacker_origin, target_origin, float(profile.x), float(profile.h), contact_area)
	_damage_player(damage, direction, contact)
	if current_health < health_before:
		hit_targets.append(1)


func _damage_player(damage: int, attacker_direction: float = 0.0, contact: Variant = null) -> void:
	if damage <= 0 or dungeon_stage == "dead" or damage_reaction.is_invulnerable() or getup_roll_remaining > 0.0 or getup_remaining > 0.0:
		return
	combo_input_remaining = 0.0
	var actual_damage := minf(current_health, damage)
	if actual_damage > 0.0:
		var origin := player - Vector2(0.0, character_height_px)
		var point: Vector2 = contact if contact is Vector2 else origin - Vector2(0.0, float(character_profiles.profile(1).h) * 0.5)
		hit_effects.play_at(point, origin, func(): return player - Vector2(0.0, character_height_px))
	current_health = maxf(0.0, current_health - damage)
	attack_anim = 0.0
	dodge_remaining = 0.0
	dodge_elapsed = 0.0
	is_moving = false
	character_actions.clear_effects()
	var knocked_down := damage_reaction.receive(actual_damage, float(_get_player_stat("max_health")), character_actions.duration(1008))
	if knocked_down and current_health > 0.0:
		getup_roll_facing = facing
		is_jumping = false
		jump_elapsed = 0.0
		character_height_px = 0.0
		var attack_direction := signf(attacker_direction) if not is_zero_approx(attacker_direction) else facing
		damage_reaction.begin_knockback(-attack_direction, character_actions.duration(1014))
		getup_pending = true
	hurt_remaining = 0.0 if knocked_down or current_health <= 0.0 else character_actions.duration(1007)
	if current_health > 0.0:
		character_actions.play(_player_down_action_id() if knocked_down else 1007, true)
	_refresh_resource_bars()
	if current_health <= 0.0:
		dungeon_stage = "dead"
		attack_anim = 0.0
		character_actions.clear_effects()
		getup_pending = false
		getup_remaining = 0.0
		character_actions.play(_player_down_action_id())
		_show_settlement(false, "主角生命归零，本次挑战失败。")


func _current_dungeon_altar_position() -> Vector2:
	if dungeon_current_node_id.is_empty():
		return Vector2.ZERO
	var map_number := int(dungeon_route_nodes[dungeon_current_node_id]["map"])
	return DUNGEON_ALTAR_POSITIONS[map_number - 1]


func _is_in_current_dungeon_altar_trigger(point: Vector2) -> bool:
	var map_number := _current_dungeon_map_number()
	if map_number <= 0:
		return false
	return _is_point_in_polygon_or_edge(point, dungeon_altar_trigger_polygons[map_number - 1])


func _activate_dungeon_portals() -> void:
	var current_node: Dictionary = dungeon_route_nodes[dungeon_current_node_id]
	current_node["completed"] = true
	dungeon_route_nodes[dungeon_current_node_id] = current_node
	dungeon_available_targets.clear()
	for target_id_value in current_node["connections"]:
		var target_id := str(target_id_value)
		dungeon_available_targets.append(target_id)
		dungeon_route_nodes[target_id]["revealed"] = true
	dungeon_stage = "portals"
	queue_redraw()


func _enter_dungeon_target(target_id: String) -> void:
	if target_id not in dungeon_available_targets:
		return
	var target_column := int(dungeon_route_nodes[target_id]["column"])
	for sibling_id_value in dungeon_columns[target_column]:
		var sibling_id := str(sibling_id_value)
		if sibling_id != target_id:
			dungeon_route_nodes[sibling_id]["dimmed"] = true
	_load_dungeon_node(target_id)


func _portal_index_from_rows(source_row: int, target_row: int) -> int:
	# The three portals express a direction relative to the current room: up, straight, down.
	return clampi(target_row - source_row + 1, 0, DUNGEON_PORTAL_POSITIONS.size() - 1)


func _portal_index_for_target(target_id: String) -> int:
	if dungeon_current_node_id.is_empty() or not dungeon_route_nodes.has(dungeon_current_node_id) or not dungeon_route_nodes.has(target_id):
		return 1
	return _portal_index_from_rows(
		int(dungeon_route_nodes[dungeon_current_node_id]["row"]),
		int(dungeon_route_nodes[target_id]["row"])
	)


func _interact() -> void:
	if modal.visible:
		return
	if state == "city":
		if _is_in_city_portal_trigger(player):
			_show_dungeon_selection()
		return
	if state != "dungeon":
		return
	if dungeon_stage == "await_altar" and dungeon_altar_tree_state == "ready" and _is_in_current_dungeon_altar_trigger(player):
		_show_altar_dialogue()
		return
	if dungeon_stage == "portals":
		for target_id in dungeon_available_targets:
			if _is_in_current_dungeon_portal_trigger(player, _portal_index_for_target(target_id)):
				_enter_dungeon_target(target_id)
				return


func _update_interact_button() -> void:
	if not is_instance_valid(interact_button):
		return
	var visible_now := false
	if state == "city":
		visible_now = _is_in_city_portal_trigger(player)
		interact_button.text = "选择副本"
	elif state == "dungeon":
		if dungeon_stage == "await_altar" and dungeon_altar_tree_state == "ready":
			visible_now = _is_in_current_dungeon_altar_trigger(player)
			interact_button.text = "祭坛对话"
		elif dungeon_stage == "portals":
			for target_id in dungeon_available_targets:
				if _is_in_current_dungeon_portal_trigger(player, _portal_index_for_target(target_id)):
					visible_now = true
					interact_button.text = "进入 %s" % target_id
					break
	interact_button.visible = visible_now and not modal.visible


func _move_player(delta: float) -> void:
	if state == "dungeon" and dungeon_stage == "dead":
		is_moving = false
		return
	if damage_reaction.down_remaining > 0.0 or hurt_remaining > 0.0:
		_update_jump(delta)
		is_moving = false
		return
	if damage_reaction.knockback_remaining > 0.0:
		is_moving = false
		return
	if getup_remaining > 0.0:
		is_moving = false
		return
	if getup_roll_remaining > 0.0:
		var roll_before := getup_roll_elapsed
		getup_roll_elapsed = minf(GETUP_ROLL_DURATION, getup_roll_elapsed + delta)
		var t0 := clampf(roll_before / GETUP_ROLL_DURATION, 0.0, 1.0)
		var t1 := clampf(getup_roll_elapsed / GETUP_ROLL_DURATION, 0.0, 1.0)
		var d0 := GETUP_ROLL_DISTANCE * (1.0 - pow(1.0 - t0, GETUP_ROLL_CURVE_POWER))
		var d1 := GETUP_ROLL_DISTANCE * (1.0 - pow(1.0 - t1, GETUP_ROLL_CURVE_POWER))
		player.x += getup_roll_direction * (d1 - d0)
		getup_roll_remaining = maxf(0.0, GETUP_ROLL_DISTANCE - d1)
		is_moving = true
		facing = getup_roll_facing
		_clamp_player_position()
		if getup_roll_remaining <= 0.0:
			getup_roll_direction = 0.0
			damage_reaction.finish_getup()
		return
	var landing_attack := is_jumping and character_actions.active_id == 2004
	_update_jump(delta)
	if landing_attack and not is_jumping:
		return
	if modal.visible or city_walkable_drag_pointer != NO_POINTER or spawn_drag_corner >= 0 or dungeon_editor_drag_pointer != NO_POINTER:
		is_moving = false
		return
	if attack_anim > 0.0:
		var requested_advance := character_actions.attack_advance(minf(delta, attack_anim))
		player.x += requested_advance
		if trace_attack_motion and not is_zero_approx(requested_advance):
			print("ATTACK_ADVANCE requested=", requested_advance, " before_clamp=", player)
		if attack_action_id != 2004:
			is_moving = false
			_clamp_player_position()
			return
	if dodge_remaining > 0.0:
		var dodge_elapsed_before := dodge_elapsed
		dodge_elapsed = minf(DODGE_DURATION, dodge_elapsed + delta)
		var dodge_progress_before := clampf(dodge_elapsed_before / DODGE_DURATION, 0.0, 1.0)
		var dodge_progress_after := clampf(dodge_elapsed / DODGE_DURATION, 0.0, 1.0)
		# Mild ease-out keeps a little deceleration without front-loading the dodge.
		var distance_before := DODGE_DISTANCE * (1.0 - pow(1.0 - dodge_progress_before, DODGE_CURVE_POWER))
		var distance_after := DODGE_DISTANCE * (1.0 - pow(1.0 - dodge_progress_after, DODGE_CURVE_POWER))
		var dodge_step := distance_after - distance_before
		dodge_remaining = maxf(0.0, DODGE_DISTANCE - distance_after)
		var vertical_input := Input.get_axis("ui_up", "ui_down")
		vertical_input += float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
		player.x += dodge_direction * dodge_step
		player.y += clampf(vertical_input, -1.0, 1.0) * DODGE_VERTICAL_SPEED * (dodge_step / DODGE_SPEED)
		facing = dodge_direction
		is_moving = true
		_clamp_player_position()
		return
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	direction.x += float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	direction.y += float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	direction += joystick_vector
	direction = direction.limit_length()
	is_moving = direction.length_squared() > 0.01
	is_walking = is_moving and (Input.is_key_pressed(KEY_SHIFT) or direction.length() < 0.65)
	if absf(direction.x) > 0.1:
		facing = signf(direction.x)
	player += direction * _effective_move_speed() * delta * (0.5 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
	_clamp_player_position()


func _clamp_point_to_city_walkable_area(position: Vector2) -> Vector2:
	if MapGeometryScript.is_point_in_polygon_or_edge(position, city_walkable_polygon):
		return position
	var result := position
	var closest_distance := INF
	for index in range(city_walkable_polygon.size()):
		var point := _closest_point_on_segment(position, city_walkable_polygon[index], city_walkable_polygon[(index + 1) % city_walkable_polygon.size()])
		var distance := point.distance_squared_to(position)
		if distance < closest_distance:
			closest_distance = distance
			result = point
	return result


func _clamp_player_position() -> void:
	if state == "city":
		player.x = clampf(player.x, PLAYER_HORIZONTAL_MARGIN, CITY_WIDTH - PLAYER_HORIZONTAL_MARGIN)
		if Geometry2D.is_point_in_polygon(player, city_walkable_polygon):
			return
		var closest_point := city_walkable_polygon[0]
		var closest_distance := INF
		for vertex_index in range(city_walkable_polygon.size()):
			var edge_start := city_walkable_polygon[vertex_index]
			var edge_end := city_walkable_polygon[(vertex_index + 1) % city_walkable_polygon.size()]
			var edge_point := _closest_point_on_segment(player, edge_start, edge_end)
			var distance := player.distance_squared_to(edge_point)
			if distance < closest_distance:
				closest_distance = distance
				closest_point = edge_point
		player = closest_point
	else:
		player = _clamp_point_to_dungeon_walkable_area(player)


func _closest_point_on_segment(point: Vector2, edge_start: Vector2, edge_end: Vector2) -> Vector2:
	return MapGeometryScript.closest_point_on_segment(point, edge_start, edge_end)


func _current_dungeon_map_number() -> int:
	if dungeon_current_node_id.is_empty() or not dungeon_route_nodes.has(dungeon_current_node_id):
		return 0
	return int(dungeon_route_nodes[dungeon_current_node_id].get("map", 0))


func _dungeon_foreground_key_for_map(map_number: int) -> String:
	if map_number == 1:
		return "start"
	if map_number == 6:
		return "boss"
	return "normal_1" if (map_number - 2) % 2 == 0 else "normal_2"


func _dungeon_world_width_for_foreground(foreground_key: String) -> float:
	match foreground_key:
		"start":
			return DUNGEON_START_FOREGROUND.get_size().x
		"boss":
			return DUNGEON_BOSS_FOREGROUND.get_size().x
		"normal_2":
			return DUNGEON_NORMAL_FOREGROUNDS[1].get_size().x
		_:
			return DUNGEON_NORMAL_FOREGROUNDS[0].get_size().x


func _dungeon_world_width_for_map(map_number: int) -> float:
	return _dungeon_world_width_for_foreground(_dungeon_foreground_key_for_map(map_number))


func _default_dungeon_walkable_polygon(world_width: float = DUNGEON_WIDTH) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(PLAYER_HORIZONTAL_MARGIN, DUNGEON_WALKABLE_TOP),
		Vector2(world_width - PLAYER_HORIZONTAL_MARGIN, DUNGEON_WALKABLE_TOP),
		Vector2(world_width - PLAYER_HORIZONTAL_MARGIN, DUNGEON_WALKABLE_BOTTOM),
		Vector2(PLAYER_HORIZONTAL_MARGIN, DUNGEON_WALKABLE_BOTTOM),
	])


func _default_dungeon_altar_trigger_polygon(center: Vector2) -> PackedVector2Array:
	var diagonal := DUNGEON_INTERACT_RANGE * 0.70710678
	return PackedVector2Array([
		center + Vector2(-DUNGEON_INTERACT_RANGE, 0.0),
		center + Vector2(-diagonal, -diagonal),
		center + Vector2(0.0, -DUNGEON_INTERACT_RANGE),
		center + Vector2(diagonal, -diagonal),
		center + Vector2(DUNGEON_INTERACT_RANGE, 0.0),
		center + Vector2(diagonal, diagonal),
		center + Vector2(0.0, DUNGEON_INTERACT_RANGE),
		center + Vector2(-diagonal, diagonal),
	])


func _current_dungeon_portal_trigger_position(portal_index: int) -> Vector2:
	var map_number := _current_dungeon_map_number()
	if map_number <= 0 or portal_index < 0 or portal_index >= DUNGEON_PORTAL_POSITIONS.size():
		return DUNGEON_PORTAL_POSITIONS[clampi(portal_index, 0, DUNGEON_PORTAL_POSITIONS.size() - 1)]
	return dungeon_portal_trigger_positions[map_number - 1][portal_index]


func _current_dungeon_portal_effect_position(portal_index: int) -> Vector2:
	var map_number := _current_dungeon_map_number()
	if map_number <= 0 or portal_index < 0 or portal_index >= DUNGEON_PORTAL_POSITIONS.size():
		return DUNGEON_PORTAL_POSITIONS[clampi(portal_index, 0, DUNGEON_PORTAL_POSITIONS.size() - 1)]
	return dungeon_portal_effect_positions[map_number - 1][portal_index]


func _current_dungeon_portal_trigger_radius(portal_index: int) -> Vector2:
	var map_number := _current_dungeon_map_number()
	if map_number <= 0 or portal_index < 0 or portal_index >= DUNGEON_PORTAL_POSITIONS.size():
		return DUNGEON_PORTAL_TRIGGER_DEFAULT_RADIUS
	return dungeon_portal_trigger_radii[map_number - 1][portal_index]


func _set_current_dungeon_portal_trigger_position(portal_index: int, position: Vector2) -> void:
	var map_number := _current_dungeon_map_number()
	if map_number <= 0 or portal_index < 0 or portal_index >= DUNGEON_PORTAL_POSITIONS.size():
		return
	var next_position := Vector2(
		clampf(position.x, 0.0, DUNGEON_WIDTH),
		clampf(position.y, 0.0, DUNGEON_HEIGHT)
	)
	var foreground_key := _dungeon_foreground_key_for_map(map_number)
	for map_index in range(dungeon_portal_trigger_positions.size()):
		if _dungeon_foreground_key_for_map(map_index + 1) == foreground_key:
			dungeon_portal_trigger_positions[map_index][portal_index] = next_position
	_save_dungeon_area_editor()
	queue_redraw()


func _set_current_dungeon_portal_trigger_radius(portal_index: int, radius: Vector2) -> void:
	var map_number := _current_dungeon_map_number()
	if map_number <= 0 or portal_index < 0 or portal_index >= DUNGEON_PORTAL_POSITIONS.size():
		return
	var next_radius := Vector2(
		clampf(radius.x, DUNGEON_PORTAL_TRIGGER_MIN_RADIUS, DUNGEON_PORTAL_TRIGGER_MAX_RADIUS),
		clampf(radius.y, DUNGEON_PORTAL_TRIGGER_MIN_RADIUS, DUNGEON_PORTAL_TRIGGER_MAX_RADIUS)
	)
	var foreground_key := _dungeon_foreground_key_for_map(map_number)
	for map_index in range(dungeon_portal_trigger_radii.size()):
		if _dungeon_foreground_key_for_map(map_index + 1) == foreground_key:
			dungeon_portal_trigger_radii[map_index][portal_index] = next_radius
	_save_dungeon_area_editor()
	queue_redraw()


func _is_in_current_dungeon_portal_trigger(point: Vector2, portal_index: int) -> bool:
	var radius := _current_dungeon_portal_trigger_radius(portal_index)
	var offset := point - _current_dungeon_portal_trigger_position(portal_index)
	return offset.x * offset.x / (radius.x * radius.x) + offset.y * offset.y / (radius.y * radius.y) <= 1.0


func _load_dungeon_area_editor() -> void:
	dungeon_walkable_polygons.clear()
	dungeon_walkable_by_foreground.clear()
	dungeon_altar_trigger_polygons.clear()
	dungeon_altar_tree_positions.clear()
	dungeon_portal_trigger_positions.clear()
	dungeon_portal_trigger_radii.clear()
	dungeon_portal_effect_positions.clear()
	dungeon_spawn_rects.clear()
	for foreground_key in DUNGEON_FOREGROUND_KEYS:
		dungeon_walkable_by_foreground[foreground_key] = _default_dungeon_walkable_polygon(_dungeon_world_width_for_foreground(foreground_key))
	for map_index in range(DUNGEON_ALTAR_POSITIONS.size()):
		dungeon_walkable_polygons.append(_default_dungeon_walkable_polygon(_dungeon_world_width_for_map(map_index + 1)))
		dungeon_altar_trigger_polygons.append(_default_dungeon_altar_trigger_polygon(DUNGEON_ALTAR_POSITIONS[map_index]))
		dungeon_altar_tree_positions.append(DUNGEON_ALTAR_POSITIONS[map_index])
		dungeon_portal_trigger_positions.append(DUNGEON_PORTAL_POSITIONS.duplicate())
		dungeon_portal_effect_positions.append(DUNGEON_PORTAL_POSITIONS.duplicate())
		dungeon_portal_trigger_radii.append([
			DUNGEON_PORTAL_TRIGGER_DEFAULT_RADIUS,
			DUNGEON_PORTAL_TRIGGER_DEFAULT_RADIUS,
			DUNGEON_PORTAL_TRIGGER_DEFAULT_RADIUS,
		])
		dungeon_spawn_rects.append(DUNGEON_SPAWN_DEFAULT_RECT)
	var config_path := dungeon_area_store if FileAccess.file_exists(dungeon_area_store) else dungeon_area_project_store
	if not FileAccess.file_exists(config_path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(config_path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var raw_foreground_walkable = parsed.get("walkable_polygons_by_foreground", {})
	var saved_foreground_walkable: Dictionary = raw_foreground_walkable if raw_foreground_walkable is Dictionary else {}
	var has_foreground_walkable := false
	for foreground_key in DUNGEON_FOREGROUND_KEYS:
		if not saved_foreground_walkable.has(foreground_key):
			continue
		var foreground_walkable := _polygon_from_serialized(saved_foreground_walkable[foreground_key])
		if _is_valid_dungeon_polygon(foreground_walkable, DUNGEON_WALKABLE_MIN_AREA, _dungeon_world_width_for_foreground(foreground_key)):
			dungeon_walkable_by_foreground[foreground_key] = foreground_walkable
			has_foreground_walkable = true
	var saved_walkable: Array = parsed.get("walkable_polygons", [])
	var saved_altar_triggers: Array = parsed.get("altar_trigger_polygons", [])
	var saved_portal_positions: Array = parsed.get("portal_trigger_positions", [])
	var saved_portal_radii: Array = parsed.get("portal_trigger_radii", [])
	var saved_portal_effect_positions: Array = parsed.get("portal_effect_positions", [])
	var saved_spawn_rects: Array = parsed.get("spawn_rects", [])
	var raw_altars_by_foreground: Variant = parsed.get("altar_trigger_polygons_by_foreground", {})
	var altars_by_foreground: Dictionary = raw_altars_by_foreground if raw_altars_by_foreground is Dictionary else {}
	var saved_altar_tree_positions: Array = parsed.get("altar_tree_positions", [])
	var raw_altar_trees_by_foreground: Variant = parsed.get("altar_tree_positions_by_foreground", {})
	var altar_trees_by_foreground: Dictionary = raw_altar_trees_by_foreground if raw_altar_trees_by_foreground is Dictionary else {}
	var raw_portal_positions_by_foreground: Variant = parsed.get("portal_trigger_positions_by_foreground", {})
	var portal_positions_by_foreground: Dictionary = raw_portal_positions_by_foreground if raw_portal_positions_by_foreground is Dictionary else {}
	var raw_portal_radii_by_foreground: Variant = parsed.get("portal_trigger_radii_by_foreground", {})
	var portal_radii_by_foreground: Dictionary = raw_portal_radii_by_foreground if raw_portal_radii_by_foreground is Dictionary else {}
	var raw_portal_effect_positions_by_foreground: Variant = parsed.get("portal_effect_positions_by_foreground", {})
	var portal_effect_positions_by_foreground: Dictionary = raw_portal_effect_positions_by_foreground if raw_portal_effect_positions_by_foreground is Dictionary else {}
	var raw_spawn_rects_by_foreground: Variant = parsed.get("spawn_rects_by_foreground", {})
	var spawn_rects_by_foreground: Dictionary = raw_spawn_rects_by_foreground if raw_spawn_rects_by_foreground is Dictionary else {}
	for map_index in range(DUNGEON_ALTAR_POSITIONS.size()):
		var has_portal_effect_position := false
		if not has_foreground_walkable and map_index < saved_walkable.size():
			var walkable := _polygon_from_serialized(saved_walkable[map_index])
			if _is_valid_dungeon_polygon(walkable, DUNGEON_WALKABLE_MIN_AREA, _dungeon_world_width_for_map(map_index + 1)):
				dungeon_walkable_polygons[map_index] = walkable
		if map_index < saved_altar_triggers.size():
			var altar_trigger := _polygon_from_serialized(saved_altar_triggers[map_index])
			if _is_valid_dungeon_polygon(altar_trigger, DUNGEON_ALTAR_TRIGGER_MIN_AREA):
				dungeon_altar_trigger_polygons[map_index] = altar_trigger
		if map_index < saved_altar_tree_positions.size():
			var saved_tree_position := _point_from_serialized(saved_altar_tree_positions[map_index], _dungeon_world_width_for_map(map_index + 1))
			if saved_tree_position != Vector2.INF:
				dungeon_altar_tree_positions[map_index] = saved_tree_position
		if map_index < saved_portal_positions.size():
			var portal_positions := _portal_positions_from_serialized(saved_portal_positions[map_index])
			if not portal_positions.is_empty():
				dungeon_portal_trigger_positions[map_index] = portal_positions
		if map_index < saved_portal_radii.size():
			var portal_radii := _portal_radii_from_serialized(saved_portal_radii[map_index])
			if not portal_radii.is_empty():
				dungeon_portal_trigger_radii[map_index] = portal_radii
		if map_index < saved_portal_effect_positions.size():
			var portal_effect_positions := _portal_positions_from_serialized(saved_portal_effect_positions[map_index])
			if not portal_effect_positions.is_empty():
				dungeon_portal_effect_positions[map_index] = portal_effect_positions
				has_portal_effect_position = true
		if map_index < saved_spawn_rects.size():
			var spawn_rect := _dungeon_spawn_rect_from_serialized(saved_spawn_rects[map_index])
			if spawn_rect.size.x >= 32.0 and spawn_rect.size.y >= 32.0:
				dungeon_spawn_rects[map_index] = spawn_rect
		var foreground_key := _dungeon_foreground_key_for_map(map_index + 1)
		if altars_by_foreground.has(foreground_key):
			var foreground_altar := _polygon_from_serialized(altars_by_foreground[foreground_key])
			if _is_valid_dungeon_polygon(foreground_altar, DUNGEON_ALTAR_TRIGGER_MIN_AREA):
				dungeon_altar_trigger_polygons[map_index] = foreground_altar
		if altar_trees_by_foreground.has(foreground_key):
			var foreground_tree_position := _point_from_serialized(altar_trees_by_foreground[foreground_key], _dungeon_world_width_for_foreground(foreground_key))
			if foreground_tree_position != Vector2.INF:
				dungeon_altar_tree_positions[map_index] = foreground_tree_position
		if portal_positions_by_foreground.has(foreground_key):
			var foreground_portal_positions := _portal_positions_from_serialized(portal_positions_by_foreground[foreground_key])
			if not foreground_portal_positions.is_empty():
				dungeon_portal_trigger_positions[map_index] = foreground_portal_positions
		if portal_radii_by_foreground.has(foreground_key):
			var foreground_portal_radii := _portal_radii_from_serialized(portal_radii_by_foreground[foreground_key])
			if not foreground_portal_radii.is_empty():
				dungeon_portal_trigger_radii[map_index] = foreground_portal_radii
		if portal_effect_positions_by_foreground.has(foreground_key):
			var foreground_portal_effect_positions := _portal_positions_from_serialized(portal_effect_positions_by_foreground[foreground_key])
			if not foreground_portal_effect_positions.is_empty():
				dungeon_portal_effect_positions[map_index] = foreground_portal_effect_positions
				has_portal_effect_position = true
		if not has_portal_effect_position:
			# Existing saves did not have an independent effect position. Keep their
			# current visual alignment by inheriting the edited trigger centres once.
			dungeon_portal_effect_positions[map_index] = dungeon_portal_trigger_positions[map_index].duplicate()
		if spawn_rects_by_foreground.has(foreground_key):
			var foreground_spawn_rect := _dungeon_spawn_rect_from_serialized(spawn_rects_by_foreground[foreground_key])
			if foreground_spawn_rect.size.x >= 32.0 and foreground_spawn_rect.size.y >= 32.0:
				dungeon_spawn_rects[map_index] = foreground_spawn_rect
	if has_foreground_walkable:
		_apply_foreground_walkables_to_map_polygons()
	else:
		_rebuild_foreground_walkables_from_map_polygons()


func _apply_foreground_walkables_to_map_polygons() -> void:
	for map_index in range(dungeon_walkable_polygons.size()):
		var foreground_key := _dungeon_foreground_key_for_map(map_index + 1)
		var walkable: PackedVector2Array = dungeon_walkable_by_foreground.get(foreground_key, _default_dungeon_walkable_polygon(_dungeon_world_width_for_foreground(foreground_key)))
		dungeon_walkable_polygons[map_index] = walkable


func _rebuild_foreground_walkables_from_map_polygons() -> void:
	for map_index in range(dungeon_walkable_polygons.size()):
		var foreground_key := _dungeon_foreground_key_for_map(map_index + 1)
		if foreground_key == "normal_1" and map_index == 3:
			continue
		if foreground_key == "normal_2" and map_index == 4:
			continue
		dungeon_walkable_by_foreground[foreground_key] = dungeon_walkable_polygons[map_index]


func _polygon_from_serialized(raw_points: Variant) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	if not raw_points is Array:
		return polygon
	for raw_point in raw_points:
		if not raw_point is Array or raw_point.size() < 2:
			polygon.clear()
			return polygon
		polygon.append(Vector2(float(raw_point[0]), float(raw_point[1])))
	return polygon


func _serialize_dungeon_polygon(polygon: PackedVector2Array) -> Array:
	var serialized: Array = []
	for point in polygon:
		serialized.append([point.x, point.y])
	return serialized


func _point_from_serialized(raw_point: Variant, world_width: float) -> Vector2:
	if not raw_point is Array or raw_point.size() < 2:
		return Vector2.INF
	var point := Vector2(float(raw_point[0]), float(raw_point[1]))
	if point.x < 0.0 or point.x > world_width or point.y < 0.0 or point.y > DUNGEON_HEIGHT:
		return Vector2.INF
	return point


func _portal_positions_from_serialized(raw_positions: Variant) -> Array:
	var positions: Array = []
	if not raw_positions is Array or raw_positions.size() != DUNGEON_PORTAL_POSITIONS.size():
		return positions
	for raw_position in raw_positions:
		if not raw_position is Array or raw_position.size() < 2:
			positions.clear()
			return positions
		var position := Vector2(float(raw_position[0]), float(raw_position[1]))
		if position.x < 0.0 or position.x > DUNGEON_WIDTH or position.y < 0.0 or position.y > DUNGEON_HEIGHT:
			positions.clear()
			return positions
		positions.append(position)
	return positions


func _serialize_dungeon_portal_positions(positions: Array) -> Array:
	var serialized: Array = []
	for position in positions:
		serialized.append([position.x, position.y])
	return serialized


func _portal_radii_from_serialized(raw_radii: Variant) -> Array:
	var radii: Array = []
	if not raw_radii is Array or raw_radii.size() != DUNGEON_PORTAL_POSITIONS.size():
		return radii
	for raw_radius in raw_radii:
		if not raw_radius is Array or raw_radius.size() < 2:
			radii.clear()
			return radii
		var radius := Vector2(float(raw_radius[0]), float(raw_radius[1]))
		if radius.x < DUNGEON_PORTAL_TRIGGER_MIN_RADIUS or radius.x > DUNGEON_PORTAL_TRIGGER_MAX_RADIUS or radius.y < DUNGEON_PORTAL_TRIGGER_MIN_RADIUS or radius.y > DUNGEON_PORTAL_TRIGGER_MAX_RADIUS:
			radii.clear()
			return radii
		radii.append(radius)
	return radii


func _serialize_dungeon_portal_radii(radii: Array) -> Array:
	var serialized: Array = []
	for radius in radii:
		serialized.append([radius.x, radius.y])
	return serialized


func _dungeon_spawn_rect_from_serialized(raw_rect: Variant) -> Rect2:
	if not raw_rect is Dictionary:
		return Rect2()
	var raw_position: Variant = raw_rect.get("position", [])
	var raw_size: Variant = raw_rect.get("size", [])
	if not raw_position is Array or raw_position.size() < 2 or not raw_size is Array or raw_size.size() < 2:
		return Rect2()
	var position := Vector2(float(raw_position[0]), float(raw_position[1]))
	var size := Vector2(float(raw_size[0]), float(raw_size[1]))
	if position.x < 0.0 or position.y < 0.0 or position.x + size.x > DUNGEON_WIDTH or position.y + size.y > DUNGEON_HEIGHT:
		return Rect2()
	return Rect2(position, size)


func _serialize_dungeon_spawn_rect(rect: Rect2) -> Dictionary:
	return {"position": [rect.position.x, rect.position.y], "size": [rect.size.x, rect.size.y]}


func _current_dungeon_spawn_rect() -> Rect2:
	var map_number := _current_dungeon_map_number()
	if map_number <= 0 or map_number > dungeon_spawn_rects.size():
		return DUNGEON_SPAWN_DEFAULT_RECT
	return dungeon_spawn_rects[map_number - 1]


func _random_dungeon_spawn_point() -> Vector2:
	var spawn_rect := _current_dungeon_spawn_rect()
	for _attempt in range(20):
		var candidate := Vector2(
			dungeon_rng.randf_range(spawn_rect.position.x, spawn_rect.end.x),
			dungeon_rng.randf_range(spawn_rect.position.y, spawn_rect.end.y)
		)
		if _is_point_in_polygon_or_edge(candidate, _current_dungeon_polygon("walkable")):
			return candidate
	return _clamp_point_to_dungeon_walkable_area(spawn_rect.get_center())


func _save_dungeon_area_editor() -> void:
	var walkable: Array = []
	var walkable_by_foreground := {}
	var altar_triggers: Array = []
	var altar_tree_positions: Array = []
	var portal_positions: Array = []
	var portal_radii: Array = []
	var portal_effect_positions: Array = []
	var spawn_rects: Array = []
	var altar_triggers_by_foreground := {}
	var altar_tree_positions_by_foreground := {}
	var portal_positions_by_foreground := {}
	var portal_radii_by_foreground := {}
	var portal_effect_positions_by_foreground := {}
	var spawn_rects_by_foreground := {}
	for foreground_key in DUNGEON_FOREGROUND_KEYS:
		var foreground_walkable: PackedVector2Array = dungeon_walkable_by_foreground.get(foreground_key, _default_dungeon_walkable_polygon(_dungeon_world_width_for_foreground(foreground_key)))
		walkable_by_foreground[foreground_key] = _serialize_dungeon_polygon(foreground_walkable)
	for map_index in range(DUNGEON_ALTAR_POSITIONS.size()):
		walkable.append(_serialize_dungeon_polygon(dungeon_walkable_polygons[map_index]))
		altar_triggers.append(_serialize_dungeon_polygon(dungeon_altar_trigger_polygons[map_index]))
		altar_tree_positions.append([dungeon_altar_tree_positions[map_index].x, dungeon_altar_tree_positions[map_index].y])
		portal_positions.append(_serialize_dungeon_portal_positions(dungeon_portal_trigger_positions[map_index]))
		portal_radii.append(_serialize_dungeon_portal_radii(dungeon_portal_trigger_radii[map_index]))
		portal_effect_positions.append(_serialize_dungeon_portal_positions(dungeon_portal_effect_positions[map_index]))
		spawn_rects.append(_serialize_dungeon_spawn_rect(dungeon_spawn_rects[map_index]))
		var foreground_key := _dungeon_foreground_key_for_map(map_index + 1)
		altar_triggers_by_foreground[foreground_key] = _serialize_dungeon_polygon(dungeon_altar_trigger_polygons[map_index])
		altar_tree_positions_by_foreground[foreground_key] = [dungeon_altar_tree_positions[map_index].x, dungeon_altar_tree_positions[map_index].y]
		portal_positions_by_foreground[foreground_key] = _serialize_dungeon_portal_positions(dungeon_portal_trigger_positions[map_index])
		portal_radii_by_foreground[foreground_key] = _serialize_dungeon_portal_radii(dungeon_portal_trigger_radii[map_index])
		portal_effect_positions_by_foreground[foreground_key] = _serialize_dungeon_portal_positions(dungeon_portal_effect_positions[map_index])
		spawn_rects_by_foreground[foreground_key] = _serialize_dungeon_spawn_rect(dungeon_spawn_rects[map_index])
	var file := FileAccess.open(dungeon_area_store, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({
			"walkable_polygons": walkable,
			"walkable_polygons_by_foreground": walkable_by_foreground,
			"altar_trigger_polygons": altar_triggers,
			"altar_trigger_polygons_by_foreground": altar_triggers_by_foreground,
			"altar_tree_positions": altar_tree_positions,
			"altar_tree_positions_by_foreground": altar_tree_positions_by_foreground,
			"portal_trigger_positions": portal_positions,
			"portal_trigger_positions_by_foreground": portal_positions_by_foreground,
			"portal_trigger_radii": portal_radii,
			"portal_trigger_radii_by_foreground": portal_radii_by_foreground,
			"portal_effect_positions": portal_effect_positions,
			"portal_effect_positions_by_foreground": portal_effect_positions_by_foreground,
			"spawn_rects": spawn_rects,
			"spawn_rects_by_foreground": spawn_rects_by_foreground,
		}))


func _is_valid_dungeon_polygon(polygon: PackedVector2Array, minimum_area: float, world_width: float = -1.0) -> bool:
	if polygon.size() < 3 or _polygon_area(polygon) < minimum_area:
		return false
	var effective_width := dungeon_world_width if world_width < 0.0 else world_width
	for point in polygon:
		if point.x < 0.0 or point.x > effective_width or point.y < 0.0 or point.y > DUNGEON_HEIGHT:
			return false
	for first_index in range(polygon.size()):
		var first_next := (first_index + 1) % polygon.size()
		if polygon[first_index].distance_squared_to(polygon[first_next]) < 1.0:
			return false
		for second_index in range(first_index + 1, polygon.size()):
			var second_next := (second_index + 1) % polygon.size()
			if first_index == second_index or first_next == second_index or second_next == first_index:
				continue
			if Geometry2D.segment_intersects_segment(polygon[first_index], polygon[first_next], polygon[second_index], polygon[second_next]) != null:
				return false
	return not Geometry2D.triangulate_polygon(polygon).is_empty()


func _polygon_area(polygon: PackedVector2Array) -> float:
	return MapGeometryScript.polygon_area(polygon)


func _is_point_in_polygon_or_edge(point: Vector2, polygon: PackedVector2Array) -> bool:
	return MapGeometryScript.is_point_in_polygon_or_edge(point, polygon)


func _current_dungeon_polygon(kind: String) -> PackedVector2Array:
	var map_number := _current_dungeon_map_number()
	if map_number <= 0:
		return PackedVector2Array()
	if kind == "walkable":
		return dungeon_walkable_by_foreground.get(_dungeon_foreground_key_for_map(map_number), dungeon_walkable_polygons[map_number - 1])
	return dungeon_altar_trigger_polygons[map_number - 1]


func _set_current_dungeon_polygon(kind: String, polygon: PackedVector2Array) -> void:
	var map_number := _current_dungeon_map_number()
	if map_number <= 0:
		return
	if kind == "walkable":
		var foreground_key := _dungeon_foreground_key_for_map(map_number)
		dungeon_walkable_by_foreground[foreground_key] = polygon
		_apply_foreground_walkables_to_map_polygons()
	else:
		var foreground_key := _dungeon_foreground_key_for_map(map_number)
		for map_index in range(dungeon_altar_trigger_polygons.size()):
			if _dungeon_foreground_key_for_map(map_index + 1) == foreground_key:
				dungeon_altar_trigger_polygons[map_index] = polygon
	_save_dungeon_area_editor()
	queue_redraw()


func _clamp_point_to_dungeon_walkable_area(point: Vector2) -> Vector2:
	var bounded := Vector2(clampf(point.x, 0.0, dungeon_world_width), clampf(point.y, 0.0, DUNGEON_HEIGHT))
	var polygon := _current_dungeon_polygon("walkable")
	if polygon.is_empty() or _is_point_in_polygon_or_edge(bounded, polygon):
		return bounded
	var closest_point := polygon[0]
	var closest_distance := INF
	for vertex_index in range(polygon.size()):
		var edge_point := _closest_point_on_segment(bounded, polygon[vertex_index], polygon[(vertex_index + 1) % polygon.size()])
		var distance := bounded.distance_squared_to(edge_point)
		if distance < closest_distance:
			closest_distance = distance
			closest_point = edge_point
	return closest_point


func _handle_dungeon_area_editor_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and _try_start_dungeon_editor_drag(event.position, -1):
				get_viewport().set_input_as_handled()
			elif not event.pressed and dungeon_editor_drag_pointer == -1:
				_finish_dungeon_editor_drag()
				get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if _try_delete_dungeon_editor_vertex(event.position):
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and dungeon_editor_drag_pointer == -1:
		if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_drag_dungeon_editor_vertex(event.position)
		else:
			_finish_dungeon_editor_drag()
		get_viewport().set_input_as_handled()


func _try_start_dungeon_editor_drag(screen_position: Vector2, pointer: int) -> bool:
	if dungeon_editor_drag_pointer != NO_POINTER:
		return false
	var world_position := screen_position + Vector2(camera_x, camera_y)
	var resize_kind := ""
	var resize_portal_index := -1
	var resize_distance := DUNGEON_EDITOR_VERTEX_RADIUS * 2.0
	for portal_index in range(DUNGEON_PORTAL_POSITIONS.size()):
		var portal_center := _current_dungeon_portal_trigger_position(portal_index)
		var portal_radius := _current_dungeon_portal_trigger_radius(portal_index)
		for handle in [{"kind": "portal_radius_x", "position": portal_center + Vector2(portal_radius.x, 0.0)}, {"kind": "portal_radius_y", "position": portal_center + Vector2(0.0, portal_radius.y)}]:
			var distance := world_position.distance_to(handle.position)
			if distance <= resize_distance:
				resize_kind = str(handle.kind)
				resize_portal_index = portal_index
				resize_distance = distance
	if resize_portal_index >= 0:
		dungeon_editor_drag_kind = resize_kind
		dungeon_editor_drag_vertex = resize_portal_index
		dungeon_editor_drag_pointer = pointer
		_reset_joystick()
		queue_redraw()
		return true
	for portal_index in range(DUNGEON_PORTAL_POSITIONS.size()):
		if world_position.distance_to(_current_dungeon_portal_trigger_position(portal_index)) <= DUNGEON_EDITOR_VERTEX_RADIUS * 2.0:
			dungeon_editor_drag_kind = "portal"
			dungeon_editor_drag_vertex = portal_index
			dungeon_editor_drag_pointer = pointer
			_reset_joystick()
			queue_redraw()
			return true
	var closest_kind := ""
	var closest_vertex := -1
	var closest_distance := DUNGEON_EDITOR_VERTEX_RADIUS
	for kind in ["walkable", "altar"]:
		var polygon := _current_dungeon_polygon(kind)
		for vertex_index in range(polygon.size()):
			var distance := world_position.distance_to(polygon[vertex_index])
			if distance <= closest_distance:
				closest_kind = kind
				closest_vertex = vertex_index
				closest_distance = distance
	if closest_vertex >= 0:
		dungeon_editor_drag_kind = closest_kind
		dungeon_editor_drag_vertex = closest_vertex
		dungeon_editor_drag_pointer = pointer
		_reset_joystick()
		queue_redraw()
		return true

	var edge_kind := ""
	var edge_index := -1
	var edge_point := Vector2.ZERO
	var edge_distance := DUNGEON_EDITOR_EDGE_TOLERANCE
	for kind in ["walkable", "altar"]:
		var polygon := _current_dungeon_polygon(kind)
		for vertex_index in range(polygon.size()):
			var candidate_point := _closest_point_on_segment(world_position, polygon[vertex_index], polygon[(vertex_index + 1) % polygon.size()])
			var distance := world_position.distance_to(candidate_point)
			if distance <= edge_distance:
				edge_kind = kind
				edge_index = vertex_index
				edge_point = candidate_point
				edge_distance = distance
	if edge_index < 0:
		return false
	var candidate := _current_dungeon_polygon(edge_kind).duplicate()
	candidate.insert(edge_index + 1, edge_point)
	var minimum_area := DUNGEON_WALKABLE_MIN_AREA if edge_kind == "walkable" else DUNGEON_ALTAR_TRIGGER_MIN_AREA
	if not _is_valid_dungeon_polygon(candidate, minimum_area):
		return false
	_set_current_dungeon_polygon(edge_kind, candidate)
	dungeon_editor_drag_kind = edge_kind
	dungeon_editor_drag_vertex = edge_index + 1
	dungeon_editor_drag_pointer = pointer
	_reset_joystick()
	return true


func _drag_dungeon_editor_vertex(screen_position: Vector2) -> void:
	if dungeon_editor_drag_pointer == NO_POINTER:
		return
	if dungeon_editor_drag_kind == "portal":
		_set_current_dungeon_portal_trigger_position(dungeon_editor_drag_vertex, screen_position + Vector2(camera_x, camera_y))
		return
	if dungeon_editor_drag_kind == "portal_radius_x" or dungeon_editor_drag_kind == "portal_radius_y":
		var portal_center := _current_dungeon_portal_trigger_position(dungeon_editor_drag_vertex)
		var radius := _current_dungeon_portal_trigger_radius(dungeon_editor_drag_vertex)
		var world_position := screen_position + Vector2(camera_x, camera_y)
		if dungeon_editor_drag_kind == "portal_radius_x":
			radius.x = absf(world_position.x - portal_center.x)
		else:
			radius.y = absf(world_position.y - portal_center.y)
		_set_current_dungeon_portal_trigger_radius(dungeon_editor_drag_vertex, radius)
		return
	var candidate := _current_dungeon_polygon(dungeon_editor_drag_kind).duplicate()
	if dungeon_editor_drag_vertex < 0 or dungeon_editor_drag_vertex >= candidate.size():
		return
	candidate[dungeon_editor_drag_vertex] = Vector2(
		clampf(screen_position.x + camera_x, 0.0, dungeon_world_width),
		clampf(screen_position.y + camera_y, 0.0, DUNGEON_HEIGHT)
	)
	var minimum_area := DUNGEON_WALKABLE_MIN_AREA if dungeon_editor_drag_kind == "walkable" else DUNGEON_ALTAR_TRIGGER_MIN_AREA
	if _is_valid_dungeon_polygon(candidate, minimum_area):
		_set_current_dungeon_polygon(dungeon_editor_drag_kind, candidate)


func _finish_dungeon_editor_drag() -> void:
	if dungeon_editor_drag_pointer == NO_POINTER:
		return
	dungeon_editor_drag_kind = ""
	dungeon_editor_drag_vertex = -1
	dungeon_editor_drag_pointer = NO_POINTER
	queue_redraw()


func _try_delete_dungeon_editor_vertex(screen_position: Vector2) -> bool:
	var world_position := screen_position + Vector2(camera_x, camera_y)
	var closest_kind := ""
	var closest_vertex := -1
	var closest_distance := DUNGEON_EDITOR_VERTEX_RADIUS
	for kind in ["walkable", "altar"]:
		var polygon := _current_dungeon_polygon(kind)
		for vertex_index in range(polygon.size()):
			var distance := world_position.distance_to(polygon[vertex_index])
			if distance <= closest_distance:
				closest_kind = kind
				closest_vertex = vertex_index
				closest_distance = distance
	if closest_vertex < 0:
		return false
	var candidate := _current_dungeon_polygon(closest_kind).duplicate()
	candidate.remove_at(closest_vertex)
	var minimum_area := DUNGEON_WALKABLE_MIN_AREA if closest_kind == "walkable" else DUNGEON_ALTAR_TRIGGER_MIN_AREA
	if not _is_valid_dungeon_polygon(candidate, minimum_area):
		return false
	_set_current_dungeon_polygon(closest_kind, candidate)
	return true


func _try_start_city_walkable_drag(screen_position: Vector2, pointer: int) -> bool:
	if city_walkable_drag_pointer != NO_POINTER:
		return false
	var world_position := screen_position + Vector2(camera_x, camera_y)
	var closest_vertex := -1
	var closest_distance := CITY_WALKABLE_EDITOR_VERTEX_RADIUS
	for vertex_index in range(city_walkable_polygon.size()):
		var distance := world_position.distance_to(city_walkable_polygon[vertex_index])
		if distance <= closest_distance:
			closest_vertex = vertex_index
			closest_distance = distance
	if closest_vertex >= 0:
		city_walkable_drag_vertex = closest_vertex
		city_walkable_drag_pointer = pointer
		_reset_joystick()
		queue_redraw()
		return true
	var edge_index := -1
	var edge_point := Vector2.ZERO
	var edge_distance := CITY_WALKABLE_EDITOR_EDGE_TOLERANCE
	for vertex_index in range(city_walkable_polygon.size()):
		var candidate_point := _closest_point_on_segment(world_position, city_walkable_polygon[vertex_index], city_walkable_polygon[(vertex_index + 1) % city_walkable_polygon.size()])
		var distance := world_position.distance_to(candidate_point)
		if distance <= edge_distance:
			edge_index = vertex_index
			edge_point = candidate_point
			edge_distance = distance
	if edge_index < 0:
		return false
	var candidate := city_walkable_polygon.duplicate()
	candidate.insert(edge_index + 1, edge_point)
	if not _is_city_walkable_polygon_usable(candidate):
		return false
	_set_city_walkable_polygon(candidate)
	city_walkable_drag_vertex = edge_index + 1
	city_walkable_drag_pointer = pointer
	_reset_joystick()
	return true


func _drag_city_walkable_vertex(screen_position: Vector2) -> void:
	if city_walkable_drag_pointer == NO_POINTER or city_walkable_drag_vertex < 0 or city_walkable_drag_vertex >= city_walkable_polygon.size():
		return
	var candidate := city_walkable_polygon.duplicate()
	candidate[city_walkable_drag_vertex] = Vector2(
		clampf(screen_position.x + camera_x, 0.0, CITY_WIDTH),
		clampf(screen_position.y + camera_y, 0.0, CITY_HEIGHT)
	)
	if _is_city_walkable_polygon_usable(candidate):
		_set_city_walkable_polygon(candidate)


func _finish_city_walkable_drag() -> void:
	if city_walkable_drag_pointer == NO_POINTER:
		return
	city_walkable_drag_vertex = -1
	city_walkable_drag_pointer = NO_POINTER
	_save_city_walkable_area()
	queue_redraw()


func _try_delete_city_walkable_vertex(screen_position: Vector2) -> bool:
	var world_position := screen_position + Vector2(camera_x, camera_y)
	var closest_vertex := -1
	var closest_distance := CITY_WALKABLE_EDITOR_VERTEX_RADIUS
	for vertex_index in range(city_walkable_polygon.size()):
		var distance := world_position.distance_to(city_walkable_polygon[vertex_index])
		if distance <= closest_distance:
			closest_vertex = vertex_index
			closest_distance = distance
	if closest_vertex < 0:
		return false
	var candidate := city_walkable_polygon.duplicate()
	candidate.remove_at(closest_vertex)
	if not _is_city_walkable_polygon_usable(candidate):
		return false
	_set_city_walkable_polygon(candidate)
	return true


func _set_city_walkable_polygon(polygon: PackedVector2Array) -> void:
	city_walkable_polygon = polygon
	_save_city_walkable_area()
	queue_redraw()


func _is_city_walkable_polygon_usable(polygon: PackedVector2Array) -> bool:
	return _is_valid_city_walkable_polygon(polygon)


func _try_start_spawn_drag(screen_position: Vector2, pointer: int) -> bool:
	if not CITY_SPAWN_EDITOR_ENABLED or spawn_drag_pointer != NO_POINTER:
		return false
	var closest_corner := -1
	var closest_distance := SPAWN_PICK_TOLERANCE
	var corners := _spawn_rect_corners(city_spawn_rect)
	for corner_index in range(corners.size()):
		var corner_screen := corners[corner_index] - Vector2(camera_x, camera_y)
		var distance := screen_position.distance_to(corner_screen)
		if distance <= closest_distance:
			closest_corner = corner_index
			closest_distance = distance
	if closest_corner < 0:
		var screen_rect := _city_spawn_screen_rect()
		if not screen_rect.has_point(screen_position):
			return false
		closest_corner = SPAWN_DRAG_MOVE
		spawn_drag_offset = screen_position + Vector2(camera_x, camera_y) - city_spawn_rect.position
	else:
		spawn_drag_offset = Vector2.ZERO
	spawn_drag_corner = closest_corner
	spawn_drag_pointer = pointer
	_reset_joystick()
	queue_redraw()
	return true


func _drag_spawn_corner(screen_position: Vector2) -> void:
	if spawn_drag_corner < 0:
		return
	var world_position := Vector2(
		clampf(screen_position.x + camera_x, 0.0, CITY_WIDTH),
		clampf(screen_position.y + camera_y, 0.0, CITY_HEIGHT)
	)
	if spawn_drag_corner == SPAWN_DRAG_MOVE:
		var moved_position := world_position - spawn_drag_offset
		moved_position.x = clampf(moved_position.x, 0.0, CITY_WIDTH - city_spawn_rect.size.x)
		moved_position.y = clampf(moved_position.y, 0.0, CITY_HEIGHT - city_spawn_rect.size.y)
		var moved_rect := Rect2(moved_position, city_spawn_rect.size)
		if _is_city_spawn_rect_valid(moved_rect):
			city_spawn_rect = moved_rect
			queue_redraw()
		return
	var left := city_spawn_rect.position.x
	var top := city_spawn_rect.position.y
	var right := city_spawn_rect.end.x
	var bottom := city_spawn_rect.end.y
	if spawn_drag_corner == 0 or spawn_drag_corner == 3:
		left = minf(world_position.x, right - SPAWN_MIN_SIZE.x)
	else:
		right = maxf(world_position.x, left + SPAWN_MIN_SIZE.x)
	if spawn_drag_corner == 0 or spawn_drag_corner == 1:
		top = minf(world_position.y, bottom - SPAWN_MIN_SIZE.y)
	else:
		bottom = maxf(world_position.y, top + SPAWN_MIN_SIZE.y)
	var candidate := Rect2(left, top, right - left, bottom - top)
	if _is_city_spawn_rect_valid(candidate):
		city_spawn_rect = candidate
		queue_redraw()


func _finish_spawn_drag() -> void:
	if spawn_drag_pointer == NO_POINTER:
		return
	spawn_drag_corner = -1
	spawn_drag_pointer = NO_POINTER
	spawn_drag_offset = Vector2.ZERO
	_save_city_spawn_area()
	queue_redraw()


func _load_city_walkable_area() -> void:
	if not FileAccess.file_exists(walkable_area_store):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(walkable_area_store))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var raw_points: Array = parsed.get("points", [])
	var loaded_polygon := PackedVector2Array()
	for raw_point in raw_points:
		if not raw_point is Array or raw_point.size() < 2:
			loaded_polygon.clear()
			break
		loaded_polygon.append(Vector2(float(raw_point[0]), float(raw_point[1])))
	if _is_valid_city_walkable_polygon(loaded_polygon):
		city_walkable_polygon = loaded_polygon
		return
	# Migrate the previous saved rectangle into the new four-point format.
	if parsed.has("top") and parsed.has("bottom"):
		var loaded_top := clampf(float(parsed.top), 0.0, CITY_HEIGHT)
		var loaded_bottom := clampf(float(parsed.bottom), 0.0, CITY_HEIGHT)
		var migrated_polygon := PackedVector2Array([
			Vector2(PLAYER_HORIZONTAL_MARGIN, loaded_top),
			Vector2(CITY_WIDTH - PLAYER_HORIZONTAL_MARGIN, loaded_top),
			Vector2(CITY_WIDTH - PLAYER_HORIZONTAL_MARGIN, loaded_bottom),
			Vector2(PLAYER_HORIZONTAL_MARGIN, loaded_bottom),
		])
		if _is_valid_city_walkable_polygon(migrated_polygon):
			city_walkable_polygon = migrated_polygon


func _load_main_city_project_config() -> void:
	if not FileAccess.file_exists(city_editor_project_store):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(city_editor_project_store))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var walkable_config: Dictionary = parsed.get("walkable_area", {})
	var loaded_polygon := PackedVector2Array()
	for raw_point in walkable_config.get("points", []):
		if not raw_point is Array or raw_point.size() < 2:
			loaded_polygon.clear()
			break
		loaded_polygon.append(Vector2(float(raw_point[0]), float(raw_point[1])))
	if _is_valid_city_walkable_polygon(loaded_polygon):
		city_walkable_polygon = loaded_polygon
	var spawn_config: Dictionary = parsed.get("spawn_area", {})
	var stored_position: Array = spawn_config.get("position", [])
	var stored_size: Array = spawn_config.get("size", [])
	if stored_position.size() >= 2 and stored_size.size() >= 2:
		var loaded_rect := Rect2(
			float(stored_position[0]),
			float(stored_position[1]),
			float(stored_size[0]),
			float(stored_size[1])
		)
		if _is_city_spawn_rect_valid(loaded_rect):
			city_spawn_rect = loaded_rect
	var stored_effects = parsed.get("effects", [])
	if stored_effects is Array:
		# An explicit empty list from the web editor disables all configurable effects.
		city_effect_configs = stored_effects
		city_effects_configured = true
	var portal_trigger: Dictionary = parsed.get("portal_trigger", {})
	var portal_position: Array = portal_trigger.get("position", [])
	var portal_radius: Array = portal_trigger.get("radius", [])
	if portal_position.size() >= 2 and portal_radius.size() >= 2:
		var loaded_position := Vector2(float(portal_position[0]), float(portal_position[1]))
		var loaded_radius := Vector2(float(portal_radius[0]), float(portal_radius[1]))
		if loaded_position.x >= 0.0 and loaded_position.x <= CITY_WIDTH and loaded_position.y >= 0.0 and loaded_position.y <= CITY_HEIGHT and loaded_radius.x >= 1.0 and loaded_radius.y >= 1.0:
			city_portal_trigger_position = loaded_position
			city_portal_trigger_radius = loaded_radius


func _is_in_city_portal_trigger(point: Vector2) -> bool:
	var offset := point - city_portal_trigger_position
	return offset.x * offset.x / (city_portal_trigger_radius.x * city_portal_trigger_radius.x) + offset.y * offset.y / (city_portal_trigger_radius.y * city_portal_trigger_radius.y) <= 1.0


func _load_city_spawn_area() -> void:
	if not FileAccess.file_exists(spawn_area_store):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(spawn_area_store))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var stored_position: Array = parsed.get("position", [])
	var stored_size: Array = parsed.get("size", [])
	if stored_position.size() < 2 or stored_size.size() < 2:
		return
	var loaded_rect := Rect2(
		float(stored_position[0]),
		float(stored_position[1]),
		float(stored_size[0]),
		float(stored_size[1])
	)
	if _is_city_spawn_rect_valid(loaded_rect):
		city_spawn_rect = loaded_rect


func _save_city_walkable_area() -> void:
	var file := FileAccess.open(walkable_area_store, FileAccess.WRITE)
	if file == null:
		return
	var points: Array = []
	for point in city_walkable_polygon:
		points.append([point.x, point.y])
	file.store_string(JSON.stringify({"points": points}))


func _save_city_spawn_area() -> void:
	var file := FileAccess.open(spawn_area_store, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({
			"position": [city_spawn_rect.position.x, city_spawn_rect.position.y],
			"size": [city_spawn_rect.size.x, city_spawn_rect.size.y],
		}))


func _spawn_rect_corners(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	])


func _is_city_spawn_rect_valid(rect: Rect2) -> bool:
	if rect.size.x < SPAWN_MIN_SIZE.x or rect.size.y < SPAWN_MIN_SIZE.y:
		return false
	if rect.position.x < 0.0 or rect.position.y < 0.0 or rect.end.x > CITY_WIDTH or rect.end.y > CITY_HEIGHT:
		return false
	return true


func _is_city_spawn_rect_inside_polygon(rect: Rect2, polygon: PackedVector2Array) -> bool:
	var corners := _spawn_rect_corners(rect)
	var samples := PackedVector2Array([
		corners[0], corners[1], corners[2], corners[3], rect.get_center(),
		(corners[0] + corners[1]) * 0.5,
		(corners[1] + corners[2]) * 0.5,
		(corners[2] + corners[3]) * 0.5,
		(corners[3] + corners[0]) * 0.5,
	])
	for sample in samples:
		if not _is_point_in_polygon_or_edge(sample, polygon):
			return false
	return true


func _is_point_in_city_walkable_area(point: Vector2) -> bool:
	if Geometry2D.is_point_in_polygon(point, city_walkable_polygon):
		return true
	for vertex_index in range(city_walkable_polygon.size()):
		var edge_start := city_walkable_polygon[vertex_index]
		var edge_end := city_walkable_polygon[(vertex_index + 1) % city_walkable_polygon.size()]
		if point.distance_squared_to(_closest_point_on_segment(point, edge_start, edge_end)) <= 0.01:
			return true
	return false


func _random_city_spawn_point() -> Vector2:
	for attempt in range(64):
		var candidate := Vector2(
			randf_range(city_spawn_rect.position.x, city_spawn_rect.end.x),
			randf_range(city_spawn_rect.position.y, city_spawn_rect.end.y)
		)
		if _is_point_in_city_walkable_area(candidate):
			return candidate
	return city_spawn_rect.get_center()


func _is_valid_city_walkable_polygon(polygon: PackedVector2Array) -> bool:
	if polygon.size() < 3 or _city_walkable_polygon_area(polygon) < WALKABLE_MIN_AREA:
		return false
	for point in polygon:
		if point.x < 0.0 or point.x > CITY_WIDTH or point.y < 0.0 or point.y > CITY_HEIGHT:
			return false
	for first_index in range(polygon.size()):
		var first_next := (first_index + 1) % polygon.size()
		if polygon[first_index].distance_squared_to(polygon[first_next]) < 1.0:
			return false
		for second_index in range(first_index + 1, polygon.size()):
			var second_next := (second_index + 1) % polygon.size()
			if first_index == second_index or first_next == second_index or second_next == first_index:
				continue
			if Geometry2D.segment_intersects_segment(polygon[first_index], polygon[first_next], polygon[second_index], polygon[second_next]) != null:
				return false
	return not Geometry2D.triangulate_polygon(polygon).is_empty()


func _city_walkable_polygon_area(polygon: PackedVector2Array) -> float:
	return MapGeometryScript.polygon_area(polygon)


func _jump() -> void:
	if damage_reaction.down_remaining > 0.0 or hurt_remaining > 0.0 or getup_roll_remaining > 0.0 or getup_remaining > 0.0:
		return
	if attack_anim > 0.0:
		return
	if state == "login" or modal.visible or city_walkable_drag_pointer != NO_POINTER or spawn_drag_corner >= 0 or dungeon_editor_drag_pointer != NO_POINTER or is_jumping or dodge_remaining > 0.0:
		return
	is_jumping = true
	jump_elapsed = 0.0


func _update_jump(delta: float) -> void:
	if not is_jumping:
		return
	jump_elapsed += delta
	var ascent_duration := JUMP_DURATION * 0.5
	var trajectory_elapsed := jump_elapsed
	if jump_elapsed >= ascent_duration:
		trajectory_elapsed = maxf(ascent_duration, jump_elapsed - JUMP_APEX_HOLD)
	var progress := minf(trajectory_elapsed / JUMP_DURATION, 1.0)
	character_height_px = 4.0 * JUMP_HEIGHT * progress * (1.0 - progress)
	if progress >= 1.0:
		is_jumping = false
		jump_elapsed = 0.0
		character_height_px = 0.0
		if character_actions.active_id == 2004:
			attack_anim = 0.0
			is_moving = false
			hurt_remaining = 0.0
			character_actions.clear_effects()
			character_actions.play(1001, true)


func _dodge() -> void:
	if damage_reaction.down_remaining > 0.0 or hurt_remaining > 0.0 or getup_roll_remaining > 0.0 or getup_remaining > 0.0:
		return
	if dodge_cooldown > 0.0:
		return
	if state not in ["city", "dungeon"] or (state == "dungeon" and dungeon_stage == "dead") or modal.visible or city_walkable_drag_pointer != NO_POINTER or spawn_drag_corner >= 0 or dungeon_editor_drag_pointer != NO_POINTER or dodge_remaining > 0.0:
		return
	# Cancel both the attack lock and every live attack hit window, even in hit stop.
	attack_anim = 0.0
	attack_cooldown = 0.0
	combo_input_remaining = 0.0
	combo_next_action = 2001
	character_actions.clear_effects()
	dodge_direction = facing
	dodge_elapsed = 0.0
	dodge_remaining = DODGE_DISTANCE
	dodge_cooldown = DODGE_COOLDOWN
	character_actions.play(1006, true)


func _begin_getup_roll() -> void:
	var horizontal := Input.get_axis("ui_left", "ui_right")
	horizontal += float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	horizontal += joystick_vector.x
	if absf(horizontal) <= 0.1:
		getup_roll_direction = 0.0
		getup_remaining = character_actions.duration(1012)
		character_actions.play(1012, true)
		return
	getup_roll_direction = signf(horizontal)
	# Forward/backward is relative to the knockdown facing, never world left/right.
	facing = getup_roll_facing
	getup_roll_action_id = 1010 if getup_roll_direction * getup_roll_facing > 0.0 else 1011
	getup_roll_elapsed = 0.0
	getup_roll_remaining = GETUP_ROLL_DISTANCE
	character_actions.play(getup_roll_action_id, true)


func _player_down_action_id() -> int:
	var phase := damage_reaction.knockdown_action()
	if phase == "floated":
		return 1013
	var transition_id := 1014 if phase == "down_fly" else 1008
	var loop_id := 1015
	if phase != "down_fly":
		return transition_id
	if character_actions.active_id == loop_id:
		return loop_id
	if character_actions.active_id == transition_id and character_actions.action_elapsed >= character_actions.duration(transition_id):
		return loop_id
	return transition_id


func _update_traveler() -> void:
	var screen_y := player.y - camera_y
	traveler.position = Vector2(player.x - camera_x, screen_y - character_height_px)
	traveler.scale = Vector2(PLAYER_SCALE * facing, PLAYER_SCALE)
	traveler.rotation = 0.0
	var action_id := 1001
	if state == "dungeon" and dungeon_stage == "dead":
		action_id = _player_down_action_id()
	elif damage_reaction.down_remaining > 0.0:
		action_id = _player_down_action_id()
	elif getup_remaining > 0.0:
		action_id = 1012
	elif attack_anim > 0.0:
		action_id = attack_action_id
	elif hurt_remaining > 0.0:
		action_id = 1007
	elif dodge_remaining > 0.0:
		action_id = 1006
	elif getup_roll_remaining > 0.0:
		action_id = getup_roll_action_id
	elif character_actions.has_attack_tail() and ((not is_moving and not is_jumping) or (is_jumping and character_actions.active_id == 2004)):
		# actionEnd releases controls, but does not replace an unfinished animation.
		action_id = character_actions.active_id
	elif is_jumping:
		action_id = 1004 if jump_elapsed < JUMP_DURATION * 0.5 + JUMP_APEX_HOLD else 1005
	elif is_moving:
		action_id = 1002 if is_walking else 1003
	if not character_actions.rows.is_empty():
		character_actions.play(action_id)
	_update_character_shadows()
	_update_scene_depth()

func _update_scene_depth() -> void:
	scene_depth.visible = state in ["city", "dungeon"]
	var entries: Array[Dictionary] = []
	if traveler.visible and state in ["city", "dungeon"]:
		entries.append({"node": traveler, "y": player.y})
	if state == "dungeon":
		if altar_tree.visible and not dungeon_current_node_id.is_empty():
			entries.append({"node": altar_tree, "y": _current_dungeon_altar_tree_position().y})
	if state in ["city", "dungeon"]:
		for monster in monsters + monster_actions.corpses:
			var canvas := monster_actions.prepare_actor_canvas(self, monster, _draw_monster)
			entries.append({"node": canvas, "y": float(monster.pos.y)})
	scene_depth.sort_entities(entries)


func _update_character_shadows() -> void:
	var values: Array[Dictionary] = []
	if state in ["city", "dungeon"] and traveler.visible:
		var profile: Dictionary = character_profiles.profile(1)
		values.append({"ground_position": player, "body_h": profile.h, "height": character_height_px, "shadow_scale_percent": profile.get("shadowScalePercent", 100.0)})
	if state in ["city", "dungeon"]:
		for monster in monsters + monster_actions.corpses:
			values.append({"ground_position": monster.pos, "body_h": monster.get("hurtbox_h", 130.0), "height": monster.get("character_height_px", 0.0), "shadow_scale_percent": monster.get("shadow_scale_percent", 100.0), "alpha": monster.get("spawn_alpha", 1.0)})
	character_shadows.update_characters(values, Vector2(camera_x, camera_y))



func _setup_player_animations() -> void:
	traveler.scale = Vector2(PLAYER_SCALE, PLAYER_SCALE)
	status_preview_player.scale = Vector2(PLAYER_SCALE, PLAYER_SCALE)
	character_actions.library_path = str(character_profiles.profile(1).modelResource)
	character_actions.config_path = character_action_store
	character_actions.setup(self, traveler, status_preview_player)
	character_actions.skill_effect_hit.connect(_on_skill_effect_hit)
	character_actions.attack_action_ended.connect(_on_attack_action_ended)


func _setup_altar_tree_animations() -> void:
	altar_tree.skeleton_data_res = ALTAR_TREE_SPINE_DATA
	altar_tree.get_animation_state().set_animation(&"1", true, 0)

func _setup_portal_effect() -> void:
	SceneDepthScript.set_layer(portal_effect, SceneDepthScript.LOWER_EFFECT_Z)
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"loop")
	frames.set_animation_speed(&"loop", PORTAL_EFFECT_FPS)
	frames.set_animation_loop(&"loop", true)
	for frame_index in range(PORTAL_EFFECT_FRAME_COUNT):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = PORTAL_EFFECT_SHEET
		atlas_frame.region = Rect2(
			(frame_index % PORTAL_EFFECT_COLUMNS) * PORTAL_EFFECT_FRAME_CELL,
			floori(frame_index / float(PORTAL_EFFECT_COLUMNS)) * PORTAL_EFFECT_FRAME_CELL,
			PORTAL_EFFECT_FRAME_CELL,
			PORTAL_EFFECT_FRAME_CELL
		)
		frames.add_frame(&"loop", atlas_frame)
	var additive_material := CanvasItemMaterial.new()
	additive_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var portal_configs: Array = city_effect_configs.filter(
		func(effect): return effect is Dictionary and effect.get("type", "") == "main_city_teleport_yellow"
	)
	if portal_configs.is_empty():
		if city_effects_configured:
			portal_effect.visible = false
			portal_effect.stop()
			return
		portal_effect.sprite_frames = frames
		portal_effect.material = additive_material
		portal_effect.visible = true
		portal_effect.play(&"loop")
		return
	portal_effect.visible = false
	for effect_index in range(portal_configs.size()):
		var effect_config: Dictionary = portal_configs[effect_index]
		var effect_node := portal_effect if effect_index == 0 else AnimatedSprite2D.new()
		if effect_index > 0:
			effect_node.name = "PortalEffect_%d" % (effect_index + 1)
			city_foreground_layer.add_child(effect_node)
		effect_node.sprite_frames = frames
		effect_node.material = additive_material
		effect_node.position = Vector2(
			float(effect_config.get("x", PORTAL.x)),
			float(effect_config.get("y", 544.0))
		)
		var effect_scale := float(effect_config.get("scale", 1.5))
		effect_node.scale = Vector2(effect_scale, effect_scale)
		effect_node.rotation_degrees = float(effect_config.get("rotation", 0.0))
		effect_node.visible = bool(effect_config.get("enabled", true))
		effect_node.play(&"loop")


func _add_grid_animation(
	frames: SpriteFrames,
	animation_name: StringName,
	sheet: Texture2D,
	columns: int,
	frame_count: int,
	fps: float,
	looping: bool,
	cell_size := Vector2i(PLAYER_FRAME_CELL, PLAYER_FRAME_CELL)
) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, looping)
	for frame_index in range(frame_count):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = sheet
		atlas_frame.region = Rect2(
			(frame_index % columns) * cell_size.x,
			floori(frame_index / float(columns)) * cell_size.y,
			cell_size.x,
			cell_size.y
		)
		frames.add_frame(animation_name, atlas_frame)


func _attack() -> void:
	if damage_reaction.down_remaining > 0.0 or hurt_remaining > 0.0 or getup_roll_remaining > 0.0 or getup_remaining > 0.0:
		return
	if state not in ["city", "dungeon"] or modal.visible or clear_time > 0.0 or (state == "dungeon" and dungeon_stage == "dead"):
		return
	# Attack cancels any remaining dodge immediately, without waiting for a window.
	if dodge_remaining > 0.0:
		dodge_remaining = 0.0
		dodge_elapsed = 0.0
		dodge_direction = 0.0
		character_actions.clear_effects()
		_start_attack_action(2005)
		return
	if attack_anim > 0.0 and character_actions.active_id == attack_action_id and character_actions.queue_combo_attack():
		return
	if character_actions.hit_stop_remaining > 0.0:
		return
	if attack_anim > 0.0:
		if attack_action_id >= 2003 or character_actions.active_id != attack_action_id or not character_actions.can_chain_attack():
			return
		attack_action_id += 1
	else:
		if attack_cooldown > 0.0:
			return
		attack_action_id = 2004 if is_jumping else (combo_next_action if combo_input_remaining > 0.0 else 2001)
	_start_attack_action(attack_action_id)


func _start_attack_action(action_id: int) -> void:
	attack_action_id = action_id
	combo_input_remaining = 0.0
	if trace_attack_motion:
		print("ATTACK_START ", JSON.stringify(character_actions.rows.get(action_id, {})), " position=", player, " facing=", facing)
	# Sample held direction when the attack starts, including a dodge cancel.
	var attack_direction := Input.get_axis("ui_left", "ui_right")
	attack_direction += float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	attack_direction += joystick_vector.x
	if absf(attack_direction) > 0.1:
		facing = signf(attack_direction)
	traveler.scale = Vector2(PLAYER_SCALE * facing, PLAYER_SCALE)
	attack_cooldown = _attack_interval()
	current_attack_duration = character_actions.duration(attack_action_id)
	if current_attack_duration <= 0.0:
		current_attack_duration = ATTACK_DURATION
	attack_anim = current_attack_duration
	is_moving = false
	if character_actions.rows.is_empty():
		traveler.get_animation_state().set_animation(&"attack1_SingleSword", false, 0)
	else:
		character_actions.advance_facing = facing
		character_actions.play(attack_action_id, true)


func _on_attack_action_ended(skill_id: int, elapsed_after_event: float = 0.0) -> void:
	if attack_anim <= 0.0 or attack_action_id != skill_id:
		return
	attack_anim = 0.0
	attack_cooldown = 0.0
	is_moving = false
	combo_next_action = skill_id + 1 if skill_id in [2001, 2002] else 2001
	combo_input_remaining = maxf(0.0, COMBO_INPUT_WINDOW - elapsed_after_event) if skill_id in [2001, 2002] else 0.0
	if skill_id in [2001, 2002] and character_actions.consume_combo_attack():
		_start_attack_action(skill_id + 1)


func _on_skill_effect_hit(skill_id: int, attack_distance_px: float, longitudinal_range_px: float = 246.09375, height_range_px: float = 0.0, hit_stop_ms: float = 0.0, hit_targets: Variant = null, contact_area: Rect2 = Rect2()) -> void:
	if skill_id < 2000 or state not in ["city", "dungeon"] or (state == "dungeon" and dungeon_stage == "dead") or current_health <= 0.0:
		return
	_apply_attack_damage(attack_distance_px, longitudinal_range_px, height_range_px, hit_stop_ms, hit_targets, contact_area)


func _apply_attack_damage(attack_distance_px: float, longitudinal_range_px: float = 246.09375, height_range_px: float = 0.0, hit_stop_ms: float = 0.0, hit_targets: Variant = null, contact_area: Rect2 = Rect2()) -> void:
	for monster in monsters:
		if hit_targets != null and hit_targets.any(func(previous): return is_same(previous, monster)):
			continue
		if bool(monster.get("active", true)) and int(monster.hp) > 0 and _is_monster_in_attack_range(monster, attack_distance_px, longitudinal_range_px, height_range_px):
			if hit_targets != null:
				hit_targets.append(monster)
			var damage_info := _compute_damage(float(_get_player_stat("attack")), float(monster.defense), true)
			var actual_damage := mini(int(damage_info.damage), int(monster.hp))
			if actual_damage > 0:
				var origin := Vector2(monster.pos) - Vector2(0.0, float(monster.get("character_height_px", 0.0)))
				var contact := HitEffectsScript.contact_point(player - Vector2(0.0, character_height_px), origin, float(monster.get("hurtbox_x", 0.0)), float(monster.get("hurtbox_h", 0.0)), contact_area)
				hit_effects.play_at(contact, origin, func(): return Vector2(monster.pos) - Vector2(0.0, float(monster.get("character_height_px", 0.0))))
			if not monster.has("damage_reaction"):
				monster.damage_reaction = DamageReactionScript.new()
			var knocked_down: bool = monster.damage_reaction.receive(actual_damage, float(monster.max_hp), character_actions.duration(1008))
			monster.hp -= actual_damage
			CityTrainingScript.restore_health(monster)
			var away_direction := signf(float(monster.pos.x) - player.x)
			if is_zero_approx(away_direction):
				away_direction = facing
			monster.damage_reaction.begin_pushback(away_direction, float(monster.get("hit_pushback_distance_px", 40.0)))
			if knocked_down and int(monster.hp) > 0 and bool(monster.get("can_be_launched", str(monster.get("monster_type", "normal")) != "boss")):
				monster.damage_reaction.begin_knockback(away_direction, monster_actions.duration(monster, "down_fly"))
			combat_rules.interrupt_monster(monster)
			monster_actions.interrupt(monster)
			if actual_damage > 0 and hit_stop_ms > 0.0:
				character_actions.start_hit_stop(hit_stop_ms)
				monster.hit_stop_remaining = maxf(float(monster.get("hit_stop_remaining", 0.0)), hit_stop_ms / 1000.0)
			_spawn_damage_floater(monster, actual_damage, bool(damage_info.crit))
			_apply_life_steal_and_mana_absorb(actual_damage, true)
	for index in range(monsters.size() - 1, -1, -1):
		if monsters[index].hp <= 0 and float(monsters[index].get("hit_stop_remaining", 0.0)) <= 0.0:
			_defeat_monster(monsters[index])


func _defeat_monster(monster: Dictionary) -> void:
	if CityTrainingScript.restore_health(monster):
		return
	pending_dungeon_experience += int(monster.experience_reward)
	_grant_monster_drops(monster)
	monster_actions.retire(monster)
	monsters.erase(monster)


func _grant_monster_drops(monster: Dictionary) -> void:
	ground_loot.spawn_monster(monster, inventory.catalog, _current_dungeon_polygon("walkable"), dungeon_rng)


func _spawn_damage_floater(monster: Dictionary, damage: int, critical: bool) -> void:
	if damage <= 0:
		return
	var texture: Texture2D = character_profiles.texture(str(monster.get("model_resource", "")), SMALL_MONSTER if int(monster.kind) == 0 else LARGE_MONSTER)
	var position := Vector2(monster.pos) - Vector2(0.0, maxf(0.0, float(monster.get("character_height_px", 0.0))))
	var model_top := monster_actions.visual_rect(monster, position, texture).position.y
	var offset_index := damage_floaters.size() % 3 - 1
	damage_floaters.append({
		"position": Vector2(float(monster.pos.x) + float(offset_index) * 16.0, model_top - 32.0),
		"damage": damage,
		"critical": critical,
		"elapsed": 0.0,
	})


func _update_damage_floaters(delta: float) -> void:
	for index in range(damage_floaters.size() - 1, -1, -1):
		damage_floaters[index]["elapsed"] = float(damage_floaters[index]["elapsed"]) + delta
		if float(damage_floaters[index]["elapsed"]) >= DAMAGE_FLOATER_DURATION:
			damage_floaters.remove_at(index)


func _is_monster_in_attack_range(monster: Dictionary, attack_distance_px: float, longitudinal_range_px: float = 246.09375, height_range_px: float = 0.0) -> bool:
	var offset: Vector2 = monster.pos - player
	# All three independent axes must pass at hit time; retain facing restriction.
	return attack_distance_px > 0.0 and combat_rules.overlaps_hurtbox(offset, float(monster.get("character_height_px", 0.0)), character_height_px, attack_distance_px, longitudinal_range_px, height_range_px, float(monster.get("hurtbox_x", 0.0)), float(monster.get("hurtbox_h", 0.0))) \
		and offset.x * facing + float(monster.get("hurtbox_x", 0.0)) * 0.5 > ATTACK_BEHIND_TOLERANCE


func _enter_city(returning: bool) -> void:
	hit_effects.clear()
	monster_actions.clear()
	ground_loot.clear()
	state = "city"
	attack_anim = 0.0
	attack_action_id = 2001
	hurt_remaining = 0.0
	damage_reaction.reset()
	combo_input_remaining = 0.0
	getup_roll_remaining = 0.0
	getup_remaining = 0.0
	getup_pending = false
	getup_roll_elapsed = 0.0
	getup_roll_direction = 0.0
	character_height_px = 0.0
	character_actions.clear_effects()
	character_actions.play(1001, true)
	_reset_joystick()
	_close_modal()
	player_name_label.text = role_name
	city_background.show()
	dungeon_background.hide()
	dungeon_menu_button.text = "选项"
	dungeon_menu_button.show()
	clear_time = -1.0
	monsters.clear()
	var training_position := _clamp_point_to_city_walkable_area(Vector2(CITY_WIDTH * 0.5, CITY_HEIGHT * 0.65))
	monsters.append(city_training.create(_monster_definition, training_position))
	damage_floaters.clear()
	is_jumping = false
	jump_elapsed = 0.0
	character_height_px = 0.0
	dodge_remaining = 0.0
	dodge_elapsed = 0.0
	if returning:
		_restore_player_resources()
		_save_current_player_profile()
	player = Vector2(PORTAL.x - 217.96875, PORTAL.y) if returning else _random_city_spawn_point()
	_clamp_player_position()
	camera_x = clampf(player.x - VIEW_WIDTH * 0.5, 0.0, CITY_WIDTH - VIEW_WIDTH)
	camera_y = clampf(player.y - PLAYER_SCREEN_BASELINE_Y, 0.0, maxf(0.0, CITY_HEIGHT - VIEW_HEIGHT))
	_update_city_parallax()
	_refresh_resource_bars()


func _update_city_parallax() -> void:
	# The three supplied city panoramas remain at native pixels.  Only their X
	# camera offsets differ, producing foreground 100%, midground 50%, and
	# background 10% horizontal motion.  The 5400px panoramas remain wide
	# enough to cover the whole 1800px view throughout the three-screen range.
	city_background.position = Vector2(0.0, -camera_y)
	city_foreground_layer.position.x = -camera_x * CITY_FOREGROUND_PARALLAX
	city_midground_layer.position.x = -camera_x * CITY_MIDGROUND_PARALLAX
	city_background_layer.position.x = -camera_x * CITY_BACKGROUND_PARALLAX


func _enter_dungeon() -> void:
	monster_actions.load_config()
	# Altar progress belongs to one challenge, even when route node IDs are reused.
	dungeon_altar_tree_activated_nodes.clear()
	dungeon_altar_tree_talked_nodes.clear()
	altar_tree_activation_elapsed = 0.0
	state = "dungeon"
	_reset_joystick()
	_close_modal()
	city_background.hide()
	dungeon_background.show()
	dungeon_menu_button.text = "菜单"
	dungeon_menu_button.show()
	clear_time = -1.0
	damage_floaters.clear()
	pending_dungeon_experience = 0
	dungeon_success_pending = false
	is_jumping = false
	jump_elapsed = 0.0
	character_height_px = 0.0
	dodge_remaining = 0.0
	dodge_elapsed = 0.0
	dungeon_rng.randomize()
	_generate_dungeon_route()
	_load_dungeon_node("2A")
	_refresh_resource_bars()


func _finish_dungeon(success: bool) -> void:
	inventory.settle_dungeon()
	if success:
		player_stats["experience"] = int(_get_player_stat("experience")) + pending_dungeon_experience
	pending_dungeon_experience = 0
	dungeon_success_pending = false
	_enter_city(true)


func _on_joystick_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and joystick_touch_index < 0:
			joystick_touch_index = event.index
			_set_joystick_from_position(event.position)
			joystick.accept_event()
		elif not event.pressed and event.index == joystick_touch_index:
			_reset_joystick()
			joystick.accept_event()
	elif event is InputEventScreenDrag and event.index == joystick_touch_index:
		_set_joystick_from_position(event.position)
		joystick.accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		joystick_mouse_active = event.pressed
		if event.pressed:
			_set_joystick_from_position(event.position)
		else:
			_reset_joystick()
		joystick.accept_event()
	elif event is InputEventMouseMotion and joystick_mouse_active:
		if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_set_joystick_from_position(event.position)
		else:
			_reset_joystick()
		joystick.accept_event()


func _set_joystick_from_position(local_position: Vector2) -> void:
	if modal.visible:
		_reset_joystick()
		return
	var knob_offset := (local_position - JOYSTICK_CENTER).limit_length(JOYSTICK_RADIUS)
	joystick_vector = knob_offset / JOYSTICK_RADIUS
	joystick_knob.position = JOYSTICK_CENTER - joystick_knob.size * 0.5 + knob_offset


func _reset_joystick() -> void:
	joystick_vector = Vector2.ZERO
	joystick_mouse_active = false
	joystick_touch_index = -1
	if is_instance_valid(joystick_knob):
		joystick_knob.position = JOYSTICK_CENTER - joystick_knob.size * 0.5


func _primary_action() -> void:
	if modal.visible:
		return
	if state == "city":
		if _is_in_city_portal_trigger(player):
			_show_dungeon_selection()
		else:
			_attack()
	elif state == "dungeon":
		_attack()


func _on_skill_pressed(skill_index: int) -> void:
	if state == "login" or modal.visible:
		return
	# The HUD exposes the four reserved skill slots now; combat effects are added with the skill system.
	last_skill_index = skill_index


func _show_status_panel() -> void:
	modal_mode = "status"
	modal_title.text = "玩家状态"
	modal_body.hide()
	status_content.show()
	modal_close_button.show()
	modal_primary_button.hide()
	modal_secondary_button.hide()
	modal_body.text = "角色：%s\n生命：%d / %d\n灵蕴：%d / %d\n所在区域：%s" % [
		role_name,
		int(roundf(current_health)),
		int(_get_player_stat("max_health")),
		int(roundf(current_mana)),
		int(_get_player_stat("max_mana")),
		_current_area_name(),
	]
	_refresh_status_panel()
	_open_modal()


func _on_inventory_changed() -> void:
	if not inventory_loading:
		_save_current_player_profile()


func _show_backpack_panel() -> void:
	modal_mode = "backpack"
	modal_title.text = "行者背包"
	status_content.hide()
	modal_body.hide()
	dungeon_selection_list.hide()
	modal_close_button.show()
	modal_primary_button.hide()
	modal_secondary_button.hide()
	inventory_panel.in_dungeon = state == "dungeon"
	inventory_panel.open_inventory()
	_open_modal()
	inventory_panel.show()
	modal.move_child(inventory_panel, modal.get_child_count() - 1)


func _show_dungeon_selection() -> void:
	modal_mode = "dungeon_select"
	status_content.hide()
	modal_title.text = "选择副本"
	modal_body.hide()
	dungeon_selection_list.show()
	modal_close_button.show()
	modal_primary_button.text = "确定进入"
	modal_primary_button.show()
	modal_primary_button.disabled = true
	modal_secondary_button.hide()
	_open_modal()


func _select_dungeon_floor_one() -> void:
	# 当前只开放一个副本，点击条目仍作为明确的选中动作，为后续多条目列表保留交互入口。
	modal_primary_button.disabled = false


func _show_altar_dialogue() -> void:
	var is_boss := str(dungeon_route_nodes[dungeon_current_node_id]["type"]) == "boss"
	if is_boss:
		_show_action_modal(
			"祭坛树",
			"灰蚀已经退去，枝路重新回应你的意志。\n本次第一层试炼已经完成。",
			"boss_altar",
			"完成对话",
			"",
			false
		)
	else:
		_show_action_modal(
			"祭坛树",
			"祭坛树确认了当前区域的完成状态。\n对话结束后，通往下一列可达区域的传送阵将同时开启。",
			"altar",
			"完成对话",
			"稍后再说",
			true
		)


func _show_dungeon_menu() -> void:
	if state != "dungeon":
		return
	_show_action_modal(
		"副本菜单",
		"当前区域：%s\n当前波次：%d\n待结算击杀经验：%d\n\n退出副本或退出游戏都会按照挑战失败处理。" % [dungeon_current_node_id, dungeon_wave, pending_dungeon_experience],
		"dungeon_menu",
		"退出副本",
		"退出游戏",
		true
	)


func _show_context_menu() -> void:
	if state == "city":
		_show_city_options()
	elif state == "dungeon":
		_show_dungeon_menu()


func _show_city_options() -> void:
	if state != "city":
		return
	_show_action_modal(
		"选项",
		"",
		"city_options",
		"退出游戏",
		"",
		true
	)


func _show_exit_confirmation() -> void:
	_show_action_modal(
		"确认退出副本",
		"退出后本次路线与区域进度不会保留，并按照挑战失败结算。是否确定退出？",
		"exit_confirm",
		"确定退出",
		"取消",
		true
	)


func _show_victory() -> void:
	_show_action_modal(
		"恭喜通关",
		"你已经击败首领并完成祭坛树对话。\n点击确定后进入本次副本结算。",
		"victory",
		"确定",
		"",
		false
	)


func _show_settlement(success: bool, reason: String = "") -> void:
	dungeon_success_pending = success
	var result_text := "挑战成功" if success else "挑战失败"
	var experience_text := "%d" % pending_dungeon_experience if success else "0（失败时经验保持不变）"
	_show_action_modal(
		"副本结算",
		"%s\n%s\n\n经过区域：%d / 6\n击杀经验结算：%s\n区域奖励：当前版本关闭\n技能与商店奖励：当前版本关闭\n\n确认后返回主城，生命与灵蕴恢复至上限。" % [result_text, reason, dungeon_chosen_path.size(), experience_text],
		"settlement",
		"确认返回",
		"",
		false
	)


func _show_action_modal(title_text: String, body_text: String, mode: String, primary_text: String, secondary_text: String, allow_close: bool) -> void:
	modal_mode = mode
	modal_title.text = title_text
	status_content.hide()
	dungeon_selection_list.hide()
	modal_body.show()
	modal_body.text = body_text
	modal_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	modal_close_button.visible = allow_close
	modal_primary_button.text = primary_text
	modal_primary_button.visible = not primary_text.is_empty()
	modal_primary_button.disabled = false
	modal_secondary_button.text = secondary_text
	modal_secondary_button.visible = not secondary_text.is_empty()
	_open_modal()


func _on_modal_primary() -> void:
	match modal_mode:
		"dungeon_select":
			_close_modal()
			_enter_dungeon()
		"altar":
			_mark_current_altar_tree_talked()
			_close_modal()
			_activate_dungeon_portals()
		"boss_altar":
			_mark_current_altar_tree_talked()
			dungeon_route_nodes[dungeon_current_node_id]["completed"] = true
			_show_victory()
		"dungeon_menu":
			_show_exit_confirmation()
		"city_options":
			get_tree().quit()
		"exit_confirm":
			_show_settlement(false, "玩家主动退出副本。")
		"victory":
			_show_settlement(true)
		"settlement":
			var success := dungeon_success_pending
			_close_modal()
			_finish_dungeon(success)


func _mark_current_altar_tree_talked() -> void:
	if dungeon_current_node_id.is_empty():
		return
	dungeon_altar_tree_talked_nodes[dungeon_current_node_id] = true
	dungeon_altar_tree_state = "talked"
	_play_altar_tree(&"talked")


func _on_modal_secondary() -> void:
	if modal_mode == "dungeon_menu":
		_finish_dungeon(false)
		get_tree().quit()
	else:
		_close_modal()


func _open_modal() -> void:
	modal.self_modulate.a = 0.0 if modal_mode == "backpack" else 1.0
	modal_title.visible = modal_mode != "backpack"
	if modal_mode == "backpack":
		modal_close_button.hide()
	if modal_mode != "backpack" and is_instance_valid(inventory_panel):
		inventory_panel.hide()
	_reset_joystick()
	modal_dim.show()
	modal.show()


func _close_modal() -> void:
	if is_instance_valid(inventory_panel):
		inventory_panel.hide()
	if is_instance_valid(modal_dim):
		modal_dim.hide()
	if is_instance_valid(modal):
		modal.hide()
	if is_instance_valid(status_content):
		status_content.hide()
	if is_instance_valid(dungeon_selection_list):
		dungeon_selection_list.hide()
	if is_instance_valid(modal_body):
		modal_body.hide()
	if is_instance_valid(modal_primary_button):
		modal_primary_button.hide()
	if is_instance_valid(modal_secondary_button):
		modal_secondary_button.hide()
	modal_mode = ""


func _on_modal_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if modal_close_button.visible or modal_mode == "backpack":
			_close_modal()
	elif event is InputEventScreenTouch and event.pressed:
		if modal_close_button.visible or modal_mode == "backpack":
			_close_modal()


func _draw() -> void:
	if state == "city":
		if CITY_WALKABLE_EDITOR_ENABLED:
			_draw_city_walkable_area_editor()
		if CITY_SPAWN_EDITOR_ENABLED:
			var screen_rect := _city_spawn_screen_rect()
			draw_rect(screen_rect, SPAWN_DEBUG_FILL, true)
			draw_rect(screen_rect, SPAWN_DEBUG_BORDER, false, 4.0)
			var corners := _spawn_rect_corners(screen_rect)
			for corner_index in range(corners.size()):
				_draw_spawn_handle(corners[corner_index], spawn_drag_corner == corner_index)
			_draw_spawn_handle(screen_rect.get_center(), spawn_drag_corner == SPAWN_DRAG_MOVE)
	elif state == "dungeon":
		if dungeon_area_editor_enabled:
			_draw_dungeon_area_editor()
		ground_loot.draw(self, Vector2(camera_x, camera_y), inventory.catalog)
		if dungeon_area_editor_enabled:
			_draw_dungeon_portals()
		_draw_dungeon_route_map()
		_draw_dungeon_stage_text()


func _city_spawn_screen_rect() -> Rect2:
	return Rect2(city_spawn_rect.position - Vector2(camera_x, camera_y), city_spawn_rect.size)


func _city_walkable_screen_polygon() -> PackedVector2Array:
	var screen_polygon := PackedVector2Array()
	for point in city_walkable_polygon:
		screen_polygon.append(point - Vector2(camera_x, camera_y))
	return screen_polygon


func _draw_city_walkable_area_editor() -> void:
	var screen_polygon := _city_walkable_screen_polygon()
	if screen_polygon.size() < 3:
		return
	draw_colored_polygon(screen_polygon, CITY_WALKABLE_DEBUG_FILL)
	var closed_polygon := screen_polygon.duplicate()
	closed_polygon.append(screen_polygon[0])
	draw_polyline(closed_polygon, CITY_WALKABLE_DEBUG_BORDER, 3.0, true)
	for vertex_index in range(screen_polygon.size()):
		var screen_position := screen_polygon[vertex_index]
		if screen_position.x < -CITY_WALKABLE_EDITOR_VERTEX_RADIUS or screen_position.x > VIEW_WIDTH + CITY_WALKABLE_EDITOR_VERTEX_RADIUS:
			continue
		if screen_position.y < -CITY_WALKABLE_EDITOR_VERTEX_RADIUS or screen_position.y > VIEW_HEIGHT + CITY_WALKABLE_EDITOR_VERTEX_RADIUS:
			continue
		var selected := city_walkable_drag_vertex == vertex_index and city_walkable_drag_pointer != NO_POINTER
		var radius := CITY_WALKABLE_EDITOR_VERTEX_RADIUS if selected else CITY_WALKABLE_EDITOR_VERTEX_RADIUS * 0.72
		draw_circle(screen_position, radius, Color(0.03, 0.1, 0.06, 0.92))
		draw_arc(screen_position, radius, 0.0, TAU, 20, Color(1.0, 1.0, 0.82, 1.0) if selected else CITY_WALKABLE_DEBUG_BORDER, 2.5, true)
		draw_string(ThemeDB.fallback_font, screen_position + Vector2(-5.0, 5.0), str(vertex_index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color.WHITE)
	var legend := Rect2(16.0, 160.0, 430.0, 82.0)
	draw_rect(legend, Color(0.025, 0.06, 0.04, 0.84), true)
	draw_rect(legend, CITY_WALKABLE_DEBUG_BORDER, false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(30.0, 188.0), "主城区域编辑", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, Color(0.98, 0.91, 0.65))
	draw_string(ThemeDB.fallback_font, Vector2(30.0, 216.0), "绿色：可行走区；橙色：出生区", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(0.82, 0.94, 0.82))
	draw_string(ThemeDB.fallback_font, Vector2(30.0, 238.0), "左键拖顶点／点边线加点；右键点顶点删点", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(0.95, 0.88, 0.72))


func _draw_spawn_handle(screen_position: Vector2, active: bool) -> void:
	if screen_position.x < -SPAWN_PICK_TOLERANCE or screen_position.x > VIEW_WIDTH + SPAWN_PICK_TOLERANCE:
		return
	if screen_position.y < -SPAWN_PICK_TOLERANCE or screen_position.y > VIEW_HEIGHT + SPAWN_PICK_TOLERANCE:
		return
	var handle_color := Color(1.0, 0.9, 0.35, 1.0) if active else SPAWN_DEBUG_BORDER
	draw_circle(screen_position, 15.0, Color(0.16, 0.08, 0.02, 0.92))
	draw_arc(screen_position, 15.0, 0.0, TAU, 24, handle_color, 3.0)
	draw_line(screen_position - Vector2(7.0, 0.0), screen_position + Vector2(7.0, 0.0), handle_color, 2.0)
	draw_line(screen_position - Vector2(0.0, 7.0), screen_position + Vector2(0.0, 7.0), handle_color, 2.0)


func _draw_dungeon_area_editor() -> void:
	var map_number := _current_dungeon_map_number()
	if map_number <= 0:
		return
	_draw_dungeon_editor_polygon(_current_dungeon_polygon("walkable"), DUNGEON_WALKABLE_DEBUG_FILL, DUNGEON_WALKABLE_DEBUG_BORDER, "walkable")
	_draw_dungeon_editor_polygon(_current_dungeon_polygon("altar"), DUNGEON_ALTAR_DEBUG_FILL, DUNGEON_ALTAR_DEBUG_BORDER, "altar")
	_draw_dungeon_portal_trigger_handles()
	var legend := Rect2(16.0, 160.0, 500.0, 140.0)
	draw_rect(legend, Color(0.025, 0.06, 0.04, 0.84), true)
	draw_rect(legend, Color(0.72, 0.85, 0.62, 0.92), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(30.0, 186.0), "副本区域编辑 · 地图 %d" % map_number, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, Color(0.98, 0.91, 0.65))
	draw_string(ThemeDB.fallback_font, Vector2(30.0, 214.0), "绿色：可行走区域　金色：祭坛树触发区域", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(0.82, 0.94, 0.82))
	draw_string(ThemeDB.fallback_font, Vector2(30.0, 242.0), "蓝色椭圆：传送阵触发范围；拖动十字调整位置", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(0.68, 0.86, 1.0))
	draw_string(ThemeDB.fallback_font, Vector2(30.0, 270.0), "拖右侧手柄调横径；拖下侧手柄调纵径", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(0.68, 0.86, 1.0))
	draw_string(ThemeDB.fallback_font, Vector2(30.0, 298.0), "左键拖顶点；左键点边线加点；右键点顶点删点", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(0.95, 0.88, 0.72))


func _draw_dungeon_editor_polygon(polygon: PackedVector2Array, fill: Color, border: Color, kind: String) -> void:
	if polygon.size() < 3:
		return
	var screen_polygon := PackedVector2Array()
	for point in polygon:
		screen_polygon.append(point - Vector2(camera_x, camera_y))
	draw_colored_polygon(screen_polygon, fill)
	var closed_polygon := screen_polygon.duplicate()
	closed_polygon.append(screen_polygon[0])
	draw_polyline(closed_polygon, border, 3.0, true)
	for vertex_index in range(screen_polygon.size()):
		var screen_position := screen_polygon[vertex_index]
		if screen_position.x < -DUNGEON_EDITOR_VERTEX_RADIUS or screen_position.x > VIEW_WIDTH + DUNGEON_EDITOR_VERTEX_RADIUS:
			continue
		if screen_position.y < -DUNGEON_EDITOR_VERTEX_RADIUS or screen_position.y > VIEW_HEIGHT + DUNGEON_EDITOR_VERTEX_RADIUS:
			continue
		var selected := dungeon_editor_drag_kind == kind and dungeon_editor_drag_vertex == vertex_index
		var radius := DUNGEON_EDITOR_VERTEX_RADIUS if selected else DUNGEON_EDITOR_VERTEX_RADIUS * 0.72
		draw_circle(screen_position, radius, Color(0.04, 0.08, 0.04, 0.9))
		draw_arc(screen_position, radius, 0.0, TAU, 20, Color(1.0, 1.0, 0.82, 1.0) if selected else border, 2.5, true)
		draw_string(ThemeDB.fallback_font, screen_position + Vector2(-5.0, 5.0), str(vertex_index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color.WHITE)


func _draw_dungeon_portal_trigger_handles() -> void:
	var labels := ["上", "中", "下"]
	for portal_index in range(DUNGEON_PORTAL_POSITIONS.size()):
		var screen_position := _current_dungeon_portal_trigger_position(portal_index) - Vector2(camera_x, camera_y)
		var trigger_radius := _current_dungeon_portal_trigger_radius(portal_index)
		if screen_position.x < -trigger_radius.x or screen_position.x > VIEW_WIDTH + trigger_radius.x:
			continue
		if screen_position.y < -trigger_radius.y or screen_position.y > VIEW_HEIGHT + trigger_radius.y:
			continue
		var selected := (dungeon_editor_drag_kind == "portal" or dungeon_editor_drag_kind.begins_with("portal_radius_")) and dungeon_editor_drag_vertex == portal_index
		var color := Color(0.72, 0.9, 1.0, 1.0) if selected else Color(0.34, 0.72, 1.0, 0.92)
		draw_ellipse_marker(screen_position, Color(color, 0.55), trigger_radius.x, trigger_radius.y, 2.0)
		draw_circle(screen_position, DUNGEON_EDITOR_VERTEX_RADIUS + 3.0, Color(0.02, 0.1, 0.2, 0.9))
		draw_arc(screen_position, DUNGEON_EDITOR_VERTEX_RADIUS + 3.0, 0.0, TAU, 20, color, 3.0, true)
		draw_line(screen_position - Vector2(10.0, 0.0), screen_position + Vector2(10.0, 0.0), color, 2.0)
		draw_line(screen_position - Vector2(0.0, 10.0), screen_position + Vector2(0.0, 10.0), color, 2.0)
		_draw_dungeon_portal_radius_handle(screen_position + Vector2(trigger_radius.x, 0.0), color, "横")
		_draw_dungeon_portal_radius_handle(screen_position + Vector2(0.0, trigger_radius.y), color, "纵")
		draw_string(ThemeDB.fallback_font, screen_position + Vector2(20.0, -15.0), "%s阵触发" % labels[portal_index], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, color)


func _draw_dungeon_portal_radius_handle(position: Vector2, color: Color, label: String) -> void:
	draw_rect(Rect2(position - Vector2(10.0, 10.0), Vector2(20.0, 20.0)), Color(0.02, 0.1, 0.2, 0.9), true)
	draw_rect(Rect2(position - Vector2(10.0, 10.0), Vector2(20.0, 20.0)), color, false, 2.0)
	draw_string(ThemeDB.fallback_font, position + Vector2(-7.0, 5.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, color)


func _draw_monster_effect_layer(layer: String, canvas: Node2D) -> void:
	if state not in ["city", "dungeon"]:
		return
	for monster in monsters + monster_actions.corpses:
		var position := Vector2(monster.pos) - Vector2(camera_x, camera_y + maxf(0.0, float(monster.get("character_height_px", 0.0))))
		monster_actions.draw_effects(canvas, monster, position, layer, float(monster.get("spawn_alpha", 1.0)))

func _draw_damage_floater_layer() -> void:
	if state in ["city", "dungeon"]:
		for damage_floater in damage_floaters:
			_draw_damage_floater(damage_floater, scene_depth.floating_text)

func _draw_monster(monster: Dictionary, canvas: Node2D = null) -> void:
	if canvas == null:
		canvas = self
	var pos: Vector2 = monster.pos - Vector2(camera_x, camera_y)
	pos.y -= maxf(0.0, float(monster.get("character_height_px", 0.0)))
	var texture: Texture2D = character_profiles.texture(str(monster.get("model_resource", "")), SMALL_MONSTER if monster.kind == 0 else LARGE_MONSTER)
	var size := texture.get_size()
	var rect := monster_actions.visual_rect(monster, pos, texture)
	var tint_colors := [Color.WHITE, Color("#9bcaff"), Color("#d890ff"), Color("#ffb56f")]
	var tint: Color = Color("#ffd2a1") if monster.hit > 0.0 else tint_colors[int(monster.kind)]
	tint.a = float(monster.get("spawn_alpha", 1.0))
	if monster_actions.draw_body(canvas, monster, pos, tint):
		pass
	elif str(monster.get("action_state", {}).get("key", "")) in ["down", "down_fly", "lying_loop"] or (monster.has("damage_reaction") and monster.damage_reaction.down_remaining > 0.0 and monster.damage_reaction.knockback_remaining <= 0.0):
		canvas.draw_set_transform(pos, PI * 0.5)
		canvas.draw_texture_rect(texture, Rect2(-size * 0.5, size), false, tint)
		canvas.draw_set_transform(Vector2.ZERO)
	else:
		canvas.draw_texture_rect(texture, rect, false, tint)
	if not bool(monster.get("active", true)) or int(monster.hp) <= 0:
		return
	var hp_ratio: float = float(monster.hp) / float(monster.max_hp)
	canvas.draw_rect(Rect2(pos.x - 73.125, rect.position.y - 24.375, 146.25, 14.0625), Color("#231f1e"))
	canvas.draw_rect(Rect2(pos.x - 70.3125, rect.position.y - 21.5625, 140.625 * hp_ratio, 8.4375), Color("#d88758"))
	canvas.draw_string(ThemeDB.fallback_font, Vector2(pos.x - 92.8125, rect.position.y - 35.625), monster.name, HORIZONTAL_ALIGNMENT_CENTER, 185.625, 23, Color("#f0e4c0"))


func _draw_damage_floater(damage_floater: Dictionary, canvas: Node2D = null) -> void:
	if canvas == null:
		canvas = self
	var progress := clampf(float(damage_floater.elapsed) / DAMAGE_FLOATER_DURATION, 0.0, 1.0)
	var screen_position: Vector2 = Vector2(damage_floater.position) - Vector2(camera_x, camera_y + DAMAGE_FLOATER_RISE * progress)
	if screen_position.x < -120.0 or screen_position.x > VIEW_WIDTH + 120.0 or screen_position.y < -80.0 or screen_position.y > VIEW_HEIGHT + 80.0:
		return
	var critical := bool(damage_floater.critical)
	var font_size := 42 if critical else 32
	var color := Color("#ffd458") if critical else Color("#fff1d2")
	color.a = 1.0 - progress
	var text_value := str(int(damage_floater.damage))
	var text_origin := Vector2(screen_position.x - 90.0, screen_position.y)
	canvas.draw_string(ThemeDB.fallback_font, text_origin + Vector2(2.0, 3.0), text_value, HORIZONTAL_ALIGNMENT_CENTER, 180.0, font_size, Color(0.08, 0.04, 0.02, color.a))
	canvas.draw_string(ThemeDB.fallback_font, text_origin, text_value, HORIZONTAL_ALIGNMENT_CENTER, 180.0, font_size, color)


func _route_node_screen_position(node_id: String) -> Vector2:
	var node: Dictionary = dungeon_route_nodes[node_id]
	return Vector2(585.0 + int(node["column"]) * 126.0, 39.0 + int(node["row"]) * 32.0)


func _draw_dungeon_route_map() -> void:
	if dungeon_route_nodes.is_empty():
		return
	var route_background := Rect2(520.0, 10.0, 760.0, 145.0)
	draw_rect(route_background, Color(0.025, 0.03, 0.02, 0.78), true)
	draw_rect(route_background, Color(0.65, 0.47, 0.2, 0.9), false, 2.0)
	for node_id_value in dungeon_route_nodes.keys():
		var node_id := str(node_id_value)
		var node: Dictionary = dungeon_route_nodes[node_id]
		for target_id_value in node["connections"]:
			var target_id := str(target_id_value)
			var target: Dictionary = dungeon_route_nodes[target_id]
			var alpha := 0.25 if bool(node["dimmed"]) or bool(target["dimmed"]) else 0.72
			draw_line(_route_node_screen_position(node_id), _route_node_screen_position(target_id), Color(0.8, 0.65, 0.32, alpha), 3.0, true)
	for node_id_value in dungeon_route_nodes.keys():
		var node_id := str(node_id_value)
		var node: Dictionary = dungeon_route_nodes[node_id]
		var pos := _route_node_screen_position(node_id)
		var color := _dungeon_type_color(str(node["type"])) if bool(node["revealed"]) else Color("#6c6b66")
		if bool(node["completed"]):
			color = Color("#77766f")
		if bool(node["dimmed"]):
			color.a = 0.28
		if node_id == dungeon_current_node_id:
			draw_circle(pos, 15.0, Color(1.0, 0.82, 0.3, 0.22), false, 4.0)
		var radius := 10.0 if str(node["type"]) == "boss" else 7.0
		draw_circle(pos, radius, color)
		var label := "首" if str(node["type"]) == "boss" else ("始" if str(node["type"]) == "start" else node_id)
		draw_string(ThemeDB.fallback_font, pos + Vector2(-18.0, 23.0), label, HORIZONTAL_ALIGNMENT_CENTER, 36.0, 14, Color(0.93, 0.88, 0.7, color.a))


func _dungeon_type_color(area_type: String) -> Color:
	match area_type:
		"normal":
			return Color("#f4c542")
		"elite":
			return Color("#4da9ff")
		"mutation":
			return Color("#ef5555")
		"boss":
			return Color("#d7b0ff")
		_:
			return Color("#e3b34b")


func _draw_dungeon_portals() -> void:
	for portal_index in range(DUNGEON_PORTAL_POSITIONS.size()):
		var screen_pos: Vector2 = _current_dungeon_portal_trigger_position(portal_index) - Vector2(camera_x, camera_y)
		if screen_pos.x < -100.0 or screen_pos.x > VIEW_WIDTH + 100.0:
			continue
		draw_ellipse_marker(screen_pos, Color(0.55, 0.46, 0.28, 0.32), 54.0, 22.0, 3.0)


func draw_ellipse_marker(center: Vector2, color: Color, radius_x: float, radius_y: float, width: float) -> void:
	var points := PackedVector2Array()
	for point_index in range(33):
		var angle := TAU * point_index / 32.0
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_polyline(points, color, width, true)


func _draw_dungeon_stage_text() -> void:
	var area_type := str(dungeon_route_nodes.get(dungeon_current_node_id, {}).get("type", ""))
	var type_names := {"start": "起始区域", "normal": "普通区域", "elite": "精英区域", "mutation": "变异区域", "boss": "首领区域"}
	var stage_names := {"spawning": "怪物正在显现", "combat": "战斗中", "wave_delay": "下一波即将出现 %.1f" % dungeon_next_wave_timer, "await_altar": "前往祭坛树完成对话", "portals": "选择已开启的传送阵", "dead": "挑战失败"}
	var text_value := "%s · %s　%s　波次 %d/2" % [dungeon_current_node_id, type_names.get(area_type, area_type), stage_names.get(dungeon_stage, dungeon_stage), dungeon_wave]
	draw_string(ThemeDB.fallback_font, Vector2(530.0, 182.0), text_value, HORIZONTAL_ALIGNMENT_CENTER, 740.0, 20, Color(0.96, 0.86, 0.6, 0.95))
