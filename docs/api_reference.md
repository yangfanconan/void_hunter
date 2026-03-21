# Void Hunter - API参考文档

**版本**: 1.0.0
**作者**: Void Hunter Team
**最后更新**: 2024

---

## 目录

1. [单例服务 API](#1-单例服务-api)
2. [角色系统 API](#2-角色系统-api)
3. [玩家系统 API](#3-玩家系统-api)
4. [技能系统 API](#4-技能系统-api)
5. [道具系统 API](#5-道具系统-api)
6. [敌人系统 API](#6-敌人系统-api)
7. [关卡系统 API](#7-关卡系统-api)
8. [UI系统 API](#8-ui系统-api)
9. [弹幕系统 API](#9-弹幕系统-api)
10. [工具类 API](#10-工具类-api)

---

## 1. 单例服务 API

### 1.1 GameManager

**文件路径**: `src/autoload/game_manager.gd`
**继承**: `Node`

游戏的核心管理器，负责游戏状态、全局事件和游戏流程控制。

#### 枚举

```gdscript
enum GameState {
    MENU,           # 主菜单
    CHARACTER_SELECT,  # 角色选择
    PLAYING,        # 游戏进行中
    PAUSED,         # 游戏暂停
    GAME_OVER,      # 游戏失败
    VICTORY         # 游戏胜利
}
```

#### 信号

| 信号 | 参数 | 描述 |
|------|------|------|
| `game_state_changed` | `old_state: GameState`, `new_state: GameState` | 游戏状态变化时触发 |
| `game_started` | - | 游戏开始时触发 |
| `game_paused` | - | 游戏暂停时触发 |
| `game_resumed` | - | 游戏恢复时触发 |
| `game_ended` | `is_victory: bool`, `stats: Dictionary` | 游戏结束时触发 |
| `character_unlocked` | `character_id: String`, `character_name: String` | 角色解锁时触发 |
| `achievement_unlocked` | `achievement_id: String` | 成就解锁时触发 |

#### 属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `current_state` | `GameState` | `MENU` | 当前游戏状态 |
| `selected_character` | `String` | `""` | 当前选择的角色ID |
| `current_level` | `int` | `1` | 当前关卡 |
| `debug_mode` | `bool` | `false` | 是否启用调试模式 |

#### 方法

##### change_state

```gdscript
func change_state(new_state: GameState) -> void
```

切换游戏状态。

**参数**:
- `new_state`: 新的游戏状态

**示例**:
```gdscript
GameManager.change_state(GameManager.GameState.PLAYING)
```

---

##### start_game

```gdscript
func start_game(character_id: String) -> void
```

开始新游戏。

**参数**:
- `character_id`: 选择的角色ID

**示例**:
```gdscript
GameManager.start_game("void_hunter")
```

---

##### pause_game

```gdscript
func pause_game() -> void
```

暂停游戏。

---

##### resume_game

```gdscript
func resume_game() -> void
```

恢复游戏。

---

##### end_game

```gdscript
func end_game(is_victory: bool) -> void
```

结束游戏。

**参数**:
- `is_victory`: 是否胜利

---

##### get_game_stats

```gdscript
func get_game_stats() -> Dictionary
```

获取游戏统计数据。

**返回值**: 包含游戏统计的字典

```gdscript
{
    "kill_count": 150,
    "play_time": 1234.5,
    "level": 5,
    "experience": 5000,
    "items_collected": 12
}
```

---

##### unlock_character

```gdscript
func unlock_character(character_id: String) -> bool
```

解锁角色。

**参数**:
- `character_id`: 角色ID

**返回值**: 是否成功解锁

---

##### is_character_unlocked

```gdscript
func is_character_unlocked(character_id: String) -> bool
```

检查角色是否已解锁。

**参数**:
- `character_id`: 角色ID

**返回值**: 是否已解锁

---

### 1.2 SaveManager

**文件路径**: `src/autoload/save_manager.gd`
**继承**: `Node`

存档管理器，负责游戏数据的持久化。

#### 枚举

```gdscript
enum SaveType {
    MANUAL,   # 手动存档
    AUTO,     # 自动存档
    QUICK     # 快速存档
}
```

#### 常量

```gdscript
const MAX_SAVE_SLOTS: int = 3       # 最大存档槽位
const SAVE_VERSION: int = 1         # 存档版本
```

#### 信号

| 信号 | 参数 | 描述 |
|------|------|------|
| `save_completed` | `success: bool`, `slot_id: int` | 存档保存完成 |
| `load_completed` | `success: bool`, `slot_id: int` | 存档加载完成 |
| `save_deleted` | `slot_id: int` | 存档删除完成 |
| `auto_save_completed` | `success: bool` | 自动保存完成 |

#### 属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `current_slot` | `int` | `0` | 当前存档槽位 |
| `auto_save_enabled` | `bool` | `true` | 是否启用自动保存 |
| `auto_save_interval` | `float` | `300.0` | 自动保存间隔（秒） |
| `debug_logging` | `bool` | `false` | 是否启用调试日志 |

#### 方法

##### save_game

```gdscript
func save_game(save_data: Dictionary, slot_id: int = -1) -> bool
```

保存游戏。

**参数**:
- `save_data`: 存档数据字典
- `slot_id`: 存档槽位（-1表示当前槽位）

**返回值**: 是否保存成功

**示例**:
```gdscript
var save_data = {
    "player_stats": player_stats.to_dictionary(),
    "skills": skill_manager.get_skill_ids(),
    "items": inventory.get_item_ids(),
    "level_index": current_level
}
SaveManager.save_game(save_data, 0)
```

---

##### load_game

```gdscript
func load_game(slot_id: int = -1) -> Dictionary
```

加载游戏。

**参数**:
- `slot_id`: 存档槽位（-1表示当前槽位）

**返回值**: 存档数据字典（失败时返回空字典）

---

##### delete_save

```gdscript
func delete_save(slot_id: int) -> bool
```

删除存档。

**参数**:
- `slot_id`: 存档槽位

**返回值**: 是否删除成功

---

##### has_save

```gdscript
func has_save(slot_id: int) -> bool
```

检查存档是否存在。

**参数**:
- `slot_id`: 存档槽位

**返回值**: 是否存在存档

---

##### get_save_info

```gdscript
func get_save_info(slot_id: int) -> Dictionary
```

获取存档信息。

**参数**:
- `slot_id`: 存档槽位

**返回值**: 存档信息字典

```gdscript
{
    "slot_id": 0,
    "version": 1,
    "timestamp": 1234567890,
    "play_time": 3600,
    "level": 5,
    "game_mode": 0
}
```

---

##### save_settings

```gdscript
func save_settings(settings: Dictionary) -> bool
```

保存游戏设置。

**参数**:
- `settings`: 设置数据字典

**返回值**: 是否保存成功

---

##### load_settings

```gdscript
func load_settings() -> Dictionary
```

加载游戏设置。

**返回值**: 设置数据字典

---

### 1.3 AudioManager

**文件路径**: `src/autoload/audio_manager.gd`
**继承**: `Node`

音频管理器，负责背景音乐和音效的播放控制。

#### 信号

| 信号 | 参数 | 描述 |
|------|------|------|
| `bgm_started` | `stream: AudioStream` | 背景音乐开始播放 |
| `bgm_stopped` | - | 背景音乐停止 |
| `volume_changed` | `bus: String`, `value: float` | 音量变化 |

#### 属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `master_volume` | `float` | `1.0` | 主音量 (0.0-1.0) |
| `bgm_volume` | `float` | `0.8` | 背景音乐音量 |
| `sfx_volume` | `float` | `1.0` | 音效音量 |

#### 方法

##### play_bgm

```gdscript
func play_bgm(stream: AudioStream, fade_time: float = 1.0) -> void
```

播放背景音乐。

**参数**:
- `stream`: 音频流
- `fade_time`: 淡入时间（秒）

**示例**:
```gdscript
AudioManager.play_bgm(preload("res://assets/audio/bgm/game.ogg"), 2.0)
```

---

##### stop_bgm

```gdscript
func stop_bgm(fade_time: float = 1.0) -> void
```

停止背景音乐。

**参数**:
- `fade_time`: 淡出时间（秒）

---

##### play_sfx

```gdscript
func play_sfx(stream_path: String, volume_db: float = 0.0) -> AudioStreamPlayer
```

播放音效。

**参数**:
- `stream_path`: 音效文件路径
- `volume_db`: 音量偏移（分贝）

**返回值**: 音频播放器实例

**示例**:
```gdscript
AudioManager.play_sfx("res://assets/audio/sfx/hit.wav")
```

---

##### set_volume

```gdscript
func set_volume(bus_name: String, value: float) -> void
```

设置音量。

**参数**:
- `bus_name`: 音频总线名称
- `value`: 音量值 (0.0-1.0)

---

### 1.4 ObjectPool

**文件路径**: `src/autoload/object_pool.gd`
**继承**: `Node`

对象池，用于优化频繁创建和销毁的对象。

#### 方法

##### get_instance

```gdscript
func get_instance(scene: PackedScene, parent: Node = null) -> Node
```

从对象池获取实例。

**参数**:
- `scene`: 场景预制体
- `parent`: 父节点（可选）

**返回值**: 场景实例

**示例**:
```gdscript
var bullet = ObjectPool.get_instance(bullet_scene, bullets_container)
bullet.global_position = spawn_position
bullet.activate()
```

---

##### return_instance

```gdscript
func return_instance(instance: Node) -> void
```

将实例返回对象池。

**参数**:
- `instance`: 要返回的实例

**示例**:
```gdscript
ObjectPool.return_instance(bullet)
```

---

##### warm_up

```gdscript
func warm_up(scene: PackedScene, count: int) -> void
```

预热对象池。

**参数**:
- `scene`: 场景预制体
- `count`: 预创建数量

**示例**:
```gdscript
# 游戏开始时预热子弹池
ObjectPool.warm_up(bullet_scene, 100)
```

---

##### clear_pool

```gdscript
func clear_pool(scene: PackedScene) -> void
```

清空指定对象池。

**参数**:
- `scene`: 场景预制体

---

## 2. 角色系统 API

### 2.1 CharacterBase

**文件路径**: `src/characters/character_base.gd`
**继承**: `Resource`
**类名**: `CharacterBase`

所有角色的基类。

#### 信号

| 信号 | 参数 | 描述 |
|------|------|------|
| `ability_used` | `ability_name: String` | 使用能力时触发 |
| `ability_ready` | `ability_name: String` | 能力冷却完成 |

#### 导出属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `character_id` | `String` | `""` | 角色唯一标识 |
| `character_name` | `String` | `""` | 角色显示名称 |
| `description` | `String` | `""` | 角色描述 |
| `portrait` | `Texture2D` | `null` | 角色头像 |
| `base_health` | `float` | `100.0` | 基础生命值 |
| `base_mana` | `float` | `50.0` | 基础法力值 |
| `base_stamina` | `float` | `100.0` | 基础体力值 |
| `base_attack` | `float` | `10.0` | 基础攻击力 |
| `base_defense` | `float` | `5.0` | 基础防御力 |
| `base_speed` | `float` | `150.0` | 基础移动速度 |
| `base_critical_chance` | `float` | `0.05` | 基础暴击率 |
| `base_critical_damage` | `float` | `1.5` | 基础暴击伤害 |

#### 方法

##### get_unlock_condition

```gdscript
func get_unlock_condition() -> Dictionary
```

获取角色解锁条件。

**返回值**: 解锁条件字典

```gdscript
{
    "type": "kill_count",
    "value": 1000,
    "description": "累计击杀1000个敌人"
}
```

---

##### use_special_ability

```gdscript
func use_special_ability() -> void
```

使用特殊能力（由子类实现）。

---

##### is_ability_ready

```gdscript
func is_ability_ready() -> bool
```

检查特殊能力是否就绪。

**返回值**: 是否就绪

---

##### get_ability_cooldown

```gdscript
func get_ability_cooldown() -> float
```

获取能力冷却时间。

**返回值**: 冷却时间（秒）

---

## 3. 玩家系统 API

### 3.1 Player

**文件路径**: `src/player/player.gd`
**继承**: `CharacterBody2D`

玩家控制器。

#### 信号

| 信号 | 参数 | 描述 |
|------|------|------|
| `died` | - | 玩家死亡时触发 |
| `damaged` | `amount: float`, `source: Node` | 受到伤害时触发 |
| `healed` | `amount: float` | 受到治疗时触发 |

#### 属性

| 属性 | 类型 | 描述 |
|------|------|------|
| `stats` | `PlayerStats` | 玩家属性引用 |
| `skill_manager` | `SkillManager` | 技能管理器引用 |
| `weapon_component` | `WeaponComponent` | 武器组件引用 |
| `is_invincible` | `bool` | 是否无敌 |

#### 方法

##### apply_damage

```gdscript
func apply_damage(amount: float, source: Node = null) -> float
```

应用伤害。

**参数**:
- `amount`: 伤害量
- `source`: 伤害来源（可选）

**返回值**: 实际伤害量

---

##### heal

```gdscript
func heal(amount: float) -> float
```

治疗玩家。

**参数**:
- `amount`: 治疗量

**返回值**: 实际治疗量

---

##### set_invincible

```gdscript
func set_invincible(duration: float) -> void
```

设置无敌状态。

**参数**:
- `duration`: 无敌持续时间（秒）

---

##### dash

```gdscript
func dash(direction: Vector2) -> void
```

冲刺。

**参数**:
- `direction`: 冲刺方向

---

### 3.2 PlayerStats

**文件路径**: `src/player/player_stats.gd`
**继承**: `Resource`
**类名**: `PlayerStats`

玩家属性管理。

#### 信号

| 信号 | 参数 | 描述 |
|------|------|------|
| `health_changed` | `current: float`, `maximum: float` | 生命值变化 |
| `mana_changed` | `current: float`, `maximum: float` | 法力值变化 |
| `stamina_changed` | `current: float`, `maximum: float` | 体力值变化 |
| `experience_changed` | `current: float`, `required: float` | 经验值变化 |
| `leveled_up` | `new_level: int` | 等级提升 |
| `stats_changed` | - | 属性变化 |

#### 常量

```gdscript
const BASE_EXPERIENCE_REQUIRED: int = 100    # 基础升级经验
const EXPERIENCE_GROWTH_RATE: float = 1.5    # 经验增长系数
const BASE_MAX_HEALTH: float = 100.0         # 基础最大生命值
const BASE_MAX_MANA: float = 50.0            # 基础最大法力值
const BASE_MAX_STAMINA: float = 100.0        # 基础最大体力值
```

#### 导出属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `level` | `int` | `1` | 当前等级 |
| `current_experience` | `int` | `0` | 当前经验值 |
| `current_health` | `float` | `100.0` | 当前生命值 |
| `current_mana` | `float` | `50.0` | 当前法力值 |
| `current_stamina` | `float` | `100.0` | 当前体力值 |
| `attack` | `float` | `10.0` | 攻击力 |
| `defense` | `float` | `5.0` | 防御力 |
| `speed` | `float` | `150.0` | 移动速度 |
| `critical_chance` | `float` | `0.05` | 暴击率 |
| `critical_damage` | `float` | `1.5` | 暴击伤害 |
| `life_steal` | `float` | `0.0` | 吸血百分比 |
| `damage_reduction` | `float` | `0.0` | 伤害减免 |

#### 方法

##### initialize

```gdscript
func initialize() -> void
```

初始化属性（计算所有加成）。

---

##### reset

```gdscript
func reset() -> void
```

重置所有属性到默认值。

---

##### apply_damage

```gdscript
func apply_damage(amount: float) -> float
```

应用伤害（考虑防御和减伤）。

**参数**:
- `amount`: 原始伤害量

**返回值**: 实际伤害量

---

##### heal

```gdscript
func heal(amount: float) -> float
```

治疗。

**参数**:
- `amount`: 治疗量

**返回值**: 实际治疗量

---

##### add_experience

```gdscript
func add_experience(amount: int) -> void
```

增加经验值。

**参数**:
- `amount`: 经验值数量

---

##### add_flat_bonus

```gdscript
func add_flat_bonus(stat_type: String, amount: float) -> void
```

添加固定属性加成。

**参数**:
- `stat_type`: 属性类型（"health", "mana", "attack", "defense", "speed"）
- `amount`: 加成数值

---

##### add_percent_bonus

```gdscript
func add_percent_bonus(stat_type: String, percent: float) -> void
```

添加百分比属性加成。

**参数**:
- `stat_type`: 属性类型
- `percent`: 加成百分比（0.1 = 10%）

---

##### calculate_final_damage

```gdscript
func calculate_final_damage(base_damage: float) -> Dictionary
```

计算最终伤害（含暴击判定）。

**参数**:
- `base_damage`: 基础伤害

**返回值**: 伤害信息字典

```gdscript
{
    "damage": 150.0,
    "is_critical": true
}
```

---

##### to_dictionary

```gdscript
func to_dictionary() -> Dictionary
```

序列化为字典。

**返回值**: 属性字典

---

##### from_dictionary

```gdscript
func from_dictionary(data: Dictionary) -> void
```

从字典加载属性。

**参数**:
- `data`: 属性字典

---

## 4. 技能系统 API

### 4.1 SkillBase

**文件路径**: `src/skills/skill_base.gd`
**继承**: `Resource`
**类名**: `SkillBase`

所有技能的基类。

#### 枚举

```gdscript
enum SkillType {
    OFFENSIVE,   # 进攻型
    DEFENSIVE,   # 防御型
    CONTROL,     # 控制型
    SUPPORT      # 辅助型
}

enum TargetType {
    SELF,        # 自身
    ENEMY,       # 敌人
    AREA,        # 区域
    DIRECTION    # 方向
}
```

#### 信号

| 信号 | 参数 | 描述 |
|------|------|------|
| `skill_activated` | `source: Node` | 技能激活时触发 |
| `skill_deactivated` | `source: Node` | 技能结束时触发 |
| `cooldown_started` | `duration: float` | 冷却开始 |
| `cooldown_ended` | - | 冷却结束 |
| `level_changed` | `new_level: int` | 等级变化 |

#### 导出属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `skill_id` | `String` | `""` | 技能唯一标识 |
| `skill_name` | `String` | `""` | 技能名称 |
| `description` | `String` | `""` | 技能描述 |
| `icon` | `Texture2D` | `null` | 技能图标 |
| `skill_type` | `SkillType` | `OFFENSIVE` | 技能类型 |
| `target_type` | `TargetType` | `ENEMY` | 目标类型 |
| `max_level` | `int` | `5` | 最大等级 |
| `cooldown` | `float` | `1.0` | 冷却时间（秒） |
| `mana_cost` | `float` | `0.0` | 法力消耗 |
| `damage` | `float` | `10.0` | 基础伤害 |
| `range` | `float` | `100.0` | 技能范围 |

#### 公共属性

| 属性 | 类型 | 描述 |
|------|------|------|
| `level` | `int` | 当前等级 |
| `is_active` | `bool` | 是否激活中 |
| `is_on_cooldown` | `bool` | 是否冷却中 |

#### 方法

##### activate

```gdscript
func activate(source: Node, target: Node = null) -> void
```

激活技能。

**参数**:
- `source`: 技能来源（通常是玩家）
- `target`: 目标（可选）

---

##### deactivate

```gdscript
func deactivate() -> void
```

停用技能。

---

##### upgrade

```gdscript
func upgrade() -> bool
```

升级技能。

**返回值**: 是否升级成功

---

##### can_activate

```gdscript
func can_activate(source: Node) -> bool
```

检查是否可以激活。

**参数**:
- `source`: 技能来源

**返回值**: 是否可以激活

---

##### get_cooldown_remaining

```gdscript
func get_cooldown_remaining() -> float
```

获取剩余冷却时间。

**返回值**: 剩余时间（秒）

---

##### get_description

```gdscript
func get_description() -> String
```

获取技能描述（含当前等级效果）。

**返回值**: 技能描述

---

### 4.2 SkillManager

**文件路径**: `src/skills/skill_manager.gd`
**继承**: `Node`

技能管理器，管理玩家已学习的技能。

#### 信号

| 信号 | 参数 | 描述 |
|------|------|------|
| `skill_added` | `skill: SkillBase` | 技能添加 |
| `skill_removed` | `skill_id: String` | 技能移除 |
| `skill_upgraded` | `skill: SkillBase` | 技能升级 |

#### 方法

##### add_skill

```gdscript
func add_skill(skill_id: String) -> SkillBase
```

添加技能。

**参数**:
- `skill_id`: 技能ID

**返回值**: 添加的技能实例

---

##### remove_skill

```gdscript
func remove_skill(skill_id: String) -> bool
```

移除技能。

**参数**:
- `skill_id`: 技能ID

**返回值**: 是否移除成功

---

##### get_skill

```gdscript
func get_skill(skill_id: String) -> SkillBase
```

获取技能。

**参数**:
- `skill_id`: 技能ID

**返回值**: 技能实例（不存在返回null）

---

##### has_skill

```gdscript
func has_skill(skill_id: String) -> bool
```

检查是否拥有技能。

**参数**:
- `skill_id`: 技能ID

**返回值**: 是否拥有

---

##### upgrade_skill

```gdscript
func upgrade_skill(skill_id: String) -> bool
```

升级技能。

**参数**:
- `skill_id`: 技能ID

**返回值**: 是否升级成功

---

##### get_all_skills

```gdscript
func get_all_skills() -> Array[SkillBase]
```

获取所有技能。

**返回值**: 技能列表

---

##### get_skill_ids

```gdscript
func get_skill_ids() -> Array[String]
```

获取所有技能ID。

**返回值**: 技能ID列表

---

## 5. 道具系统 API

### 5.1 ItemBase

**文件路径**: `src/items/item_base.gd`
**继承**: `Resource`
**类名**: `ItemBase`

所有道具的基类。

#### 枚举

```gdscript
enum ItemType {
    WEAPON,       # 武器
    ARMOR,        # 护甲
    ACCESSORY,    # 饰品
    CONSUMABLE,   # 消耗品
    SPECIAL       # 特殊道具
}

enum Rarity {
    COMMON,       # 普通
    UNCOMMON,     # 优秀
    RARE,         # 稀有
    EPIC,         # 史诗
    LEGENDARY     # 传说
}
```

#### 信号

| 信号 | 参数 | 描述 |
|------|------|------|
| `item_picked_up` | `player: Node` | 道具被拾取 |
| `item_dropped` | `player: Node` | 道具被丢弃 |
| `effect_applied` | `target: Node` | 效果应用 |

#### 导出属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `item_id` | `String` | `""` | 道具唯一标识 |
| `item_name` | `String` | `""` | 道具名称 |
| `description` | `String` | `""` | 道具描述 |
| `icon` | `Texture2D` | `null` | 道具图标 |
| `item_type` | `ItemType` | `WEAPON` | 道具类型 |
| `rarity` | `Rarity` | `COMMON` | 稀有度 |
| `max_stack` | `int` | `1` | 最大堆叠数量 |
| `effects` | `Dictionary` | `{}` | 道具效果 |

#### 方法

##### on_pickup

```gdscript
func on_pickup(player: Node) -> void
```

拾取时调用。

**参数**:
- `player`: 拾取者

---

##### on_drop

```gdscript
func on_drop(player: Node) -> void
```

丢弃时调用。

**参数**:
- `player`: 丢弃者

---

##### on_use

```gdscript
func on_use(player: Node) -> bool
```

使用时调用（消耗品）。

**参数**:
- `player`: 使用者

**返回值**: 是否使用成功

---

##### on_update

```gdscript
func on_update(player: Node, delta: float) -> void
```

每帧更新（被动效果）。

**参数**:
- `player`: 拥有者
- `delta`: 帧时间

---

##### get_effects_description

```gdscript
func get_effects_description() -> String
```

获取效果描述文本。

**返回值**: 效果描述

---

### 5.2 ItemRegistry

**文件路径**: `src/items/item_registry.gd`
**继承**: `Node`

道具注册表，管理所有道具定义。

#### 方法

##### register_item

```gdscript
func register_item(item: ItemBase) -> void
```

注册道具。

**参数**:
- `item`: 道具实例

---

##### get_item

```gdscript
func get_item(item_id: String) -> ItemBase
```

获取道具定义。

**参数**:
- `item_id`: 道具ID

**返回值**: 道具实例（不存在返回null）

---

##### get_items_by_type

```gdscript
func get_items_by_type(item_type: ItemBase.ItemType) -> Array[ItemBase]
```

按类型获取道具。

**参数**:
- `item_type`: 道具类型

**返回值**: 道具列表

---

##### get_items_by_rarity

```gdscript
func get_items_by_rarity(rarity: ItemBase.Rarity) -> Array[ItemBase]
```

按稀有度获取道具。

**参数**:
- `rarity`: 稀有度

**返回值**: 道具列表

---

### 5.3 DropSystem

**文件路径**: `src/items/drop_system.gd`
**继承**: `Node`

掉落系统，管理敌人掉落。

#### 信号

| 信号 | 参数 | 描述 |
|------|------|------|
| `item_dropped` | `item: ItemBase`, `position: Vector2` | 道具掉落 |

#### 方法

##### drop_item

```gdscript
func drop_item(position: Vector2, item_id: String = "") -> void
```

掉落道具。

**参数**:
- `position`: 掉落位置
- `item_id`: 指定道具ID（为空则随机）

---

##### generate_loot

```gdscript
func generate_loot(enemy_type: String, difficulty: float) -> Array[String]
```

生成战利品列表。

**参数**:
- `enemy_type`: 敌人类型
- `difficulty`: 难度系数

**返回值**: 道具ID列表

---

## 6. 敌人系统 API

### 6.1 EnemyBase

**文件路径**: `src/enemies/enemy_base.gd`
**继承**: `CharacterBody2D`
**类名**: `EnemyBase`

所有敌人的基类。

#### 枚举

```gdscript
enum EnemyType {
    MELEE,    # 近战
    RANGED,   # 远程
    TANK,     # 坦克
    ELITE,    # 精英
    BOSS      # Boss
}

enum AIState {
    IDLE,     # 空闲
    PATROL,   # 巡逻
    CHASE,    # 追击
    ATTACK,   # 攻击
    STUNNED,  # 眩晕
    DEAD      # 死亡
}
```

#### 信号

| 信号 | 参数 | 描述 |
|------|------|------|
| `died` | - | 敌人死亡 |
| `damaged` | `amount: float` | 受到伤害 |
| `state_changed` | `old_state: AIState`, `new_state: AIState` | AI状态变化 |
| `target_acquired` | `target: Node` | 发现目标 |
| `target_lost` | - | 丢失目标 |

#### 导出属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `enemy_id` | `String` | `""` | 敌人唯一标识 |
| `enemy_name` | `String` | `""` | 敌人名称 |
| `enemy_type` | `EnemyType` | `MELEE` | 敌人类型 |
| `base_health` | `float` | `50.0` | 基础生命值 |
| `base_damage` | `float` | `10.0` | 基础伤害 |
| `base_speed` | `float` | `80.0` | 基础速度 |
| `experience_value` | `int` | `10` | 经验值奖励 |
| `detection_range` | `float` | `200.0` | 检测范围 |
| `attack_range` | `float` | `50.0` | 攻击范围 |

#### 方法

##### initialize

```gdscript
func initialize(stats: Dictionary = {}) -> void
```

初始化敌人。

**参数**:
- `stats`: 属性覆盖字典

---

##### apply_damage

```gdscript
func apply_damage(amount: float, source: Node = null) -> float
```

应用伤害。

**参数**:
- `amount`: 伤害量
- `source`: 伤害来源

**返回值**: 实际伤害量

---

##### attack

```gdscript
func attack() -> void
```

执行攻击。

---

##### die

```gdscript
func die() -> void
```

死亡处理。

---

##### set_stunned

```gdscript
func set_stunned(duration: float) -> void
```

设置眩晕状态。

**参数**:
- `duration`: 眩晕持续时间

---

##### set_target

```gdscript
func set_target(target: Node) -> void
```

设置攻击目标。

**参数**:
- `target`: 目标节点

---

## 7. 关卡系统 API

### 7.1 LevelManager

**文件路径**: `src/levels/level_manager.gd`
**继承**: `Node`

关卡管理器。

#### 信号

| 信号 | 参数 | 描述 |
|------|------|------|
| `level_loaded` | `level_index: int` | 关卡加载完成 |
| `level_started` | `level_index: int` | 关卡开始 |
| `level_completed` | `level_index: int` | 关卡完成 |
| `theme_changed` | `theme: LevelTheme` | 主题变化 |

#### 方法

##### load_level

```gdscript
func load_level(level_index: int) -> void
```

加载关卡。

**参数**:
- `level_index`: 关卡索引

---

##### get_current_theme

```gdscript
func get_current_theme() -> LevelTheme
```

获取当前关卡主题。

**返回值**: 关卡主题

---

##### get_level_count

```gdscript
func get_level_count() -> int
```

获取关卡总数。

**返回值**: 关卡数量

---

### 7.2 LevelGenerator

**文件路径**: `src/levels/level_generator.gd`
**继承**: `Node`

关卡生成器。

#### 方法

##### generate

```gdscript
func generate(theme: LevelTheme, size: Vector2i) -> Dictionary
```

生成关卡地图。

**参数**:
- `theme`: 关卡主题
- `size`: 地图尺寸

**返回值**: 地图数据

```gdscript
{
    "tiles": [],           # 瓦片数据
    "walls": [],           # 墙壁位置
    "spawn_points": [],    # 生成点
    "decorations": []      # 装饰物
}
```

---

### 7.3 LevelTheme

**文件路径**: `src/levels/themes/level_theme.gd`
**继承**: `Resource`
**类名**: `LevelTheme`

关卡主题配置。

#### 枚举

```gdscript
enum EnvironmentType {
    DUNGEON,   # 地牢
    FOREST,    # 森林
    DESERT,    # 沙漠
    ICE,       # 冰雪
    VOLCANIC,  # 火山
    VOID,      # 虚空
    CASTLE     # 城堡
}
```

#### 导出属性

| 属性 | 类型 | 描述 |
|------|------|------|
| `theme_id` | `String` | 主题ID |
| `theme_name` | `String` | 主题名称 |
| `environment_type` | `EnvironmentType` | 环境类型 |
| `background_color` | `Color` | 背景颜色 |
| `ambient_light_color` | `Color` | 环境光颜色 |
| `enemy_pool` | `Array[PackedScene]` | 敌人池 |
| `boss_pool` | `Array[PackedScene]` | Boss池 |
| `item_pool` | `Array[String]` | 道具池 |
| `base_difficulty` | `float` | 基础难度 |
| `difficulty_growth` | `float` | 难度增长率 |

---

## 8. UI系统 API

### 8.1 UIManager

**文件路径**: `src/ui/ui_manager.gd`
**继承**: `CanvasLayer`
**类名**: `UIManager`

UI管理器。

#### 枚举

```gdscript
enum UILayer {
    BACKGROUND,      # 背景层
    GAME,            # 游戏层
    POPUP,           # 弹出层
    MODAL,           # 模态层
    NOTIFICATION,    # 通知层
    LOADING          # 加载层
}
```

#### 信号

| 信号 | 参数 | 描述 |
|------|------|------|
| `ui_opened` | `ui_name: String` | UI打开 |
| `ui_closed` | `ui_name: String` | UI关闭 |
| `notification_displayed` | `type: int`, `message: String` | 通知显示 |

#### 方法

##### show_main_menu

```gdscript
func show_main_menu() -> void
```

显示主菜单。

---

##### show_hud

```gdscript
func show_hud() -> void
```

显示游戏HUD。

---

##### show_pause_menu

```gdscript
func show_pause_menu() -> void
```

显示暂停菜单。

---

##### show_game_over

```gdscript
func show_game_over(is_victory: bool, stats: Dictionary = {}) -> void
```

显示游戏结束界面。

**参数**:
- `is_victory`: 是否胜利
- `stats`: 游戏统计

---

##### show_notification

```gdscript
func show_notification(
    type: NotificationSystem.NotificationType,
    title: String,
    message: String,
    icon: Texture2D = null,
    duration: float = 3.0
) -> void
```

显示通知。

**参数**:
- `type`: 通知类型
- `title`: 标题
- `message`: 消息内容
- `icon`: 图标
- `duration`: 显示时长

---

##### create_damage_number

```gdscript
func create_damage_number(
    world_position: Vector2,
    value: float,
    type: DamageNumber.NumberType = DamageNumber.NumberType.DAMAGE
) -> DamageNumber
```

创建伤害数字。

**参数**:
- `world_position`: 世界坐标
- `value`: 数值
- `type`: 数字类型

**返回值**: 伤害数字实例

---

## 9. 弹幕系统 API

### 9.1 BulletBase

**文件路径**: `src/projectiles/bullet_base.gd`
**继承**: `Area2D`
**类名**: `BulletBase`

子弹基类。

#### 信号

| 信号 | 参数 | 描述 |
|------|------|------|
| `hit` | `target: Node` | 命中目标 |
| `missed` | - | 未命中（超出范围） |

#### 导出属性

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `damage` | `float` | `10.0` | 伤害值 |
| `speed` | `float` | `400.0` | 飞行速度 |
| `lifetime` | `float` | `3.0` | 存活时间 |
| `penetration` | `int` | `1` | 穿透次数 |
| `homing` | `bool` | `false` | 是否追踪 |

#### 方法

##### initialize

```gdscript
func initialize(
    position: Vector2,
    direction: Vector2,
    damage: float
) -> void
```

初始化子弹。

**参数**:
- `position`: 初始位置
- `direction`: 飞行方向
- `damage`: 伤害值

---

##### deactivate

```gdscript
func deactivate() -> void
```

停用子弹（返回对象池）。

---

## 10. 工具类 API

### 10.1 DebugTools

**文件路径**: `src/utils/debug_tools.gd`
**继承**: `Node`

调试工具集。

#### 方法

##### log_debug

```gdscript
static func log_debug(message: String, category: String = "General") -> void
```

输出调试日志。

**参数**:
- `message`: 日志消息
- `category`: 日志分类

---

##### draw_debug_circle

```gdscript
static func draw_debug_circle(
    canvas: CanvasItem,
    center: Vector2,
    radius: float,
    color: Color = Color.RED
) -> void
```

绘制调试圆圈。

**参数**:
- `canvas`: 画布节点
- `center`: 圆心
- `radius`: 半径
- `color`: 颜色

---

##### spawn_debug_marker

```gdscript
static func spawn_debug_marker(position: Vector2, duration: float = 1.0) -> void
```

生成调试标记。

**参数**:
- `position`: 位置
- `duration`: 持续时间

---

## 附录

### A. 完整信号列表

| 类 | 信号 | 参数 |
|----|------|------|
| GameManager | game_state_changed | old_state, new_state |
| GameManager | game_started | - |
| GameManager | game_paused | - |
| GameManager | game_resumed | - |
| GameManager | game_ended | is_victory, stats |
| GameManager | character_unlocked | character_id, character_name |
| SaveManager | save_completed | success, slot_id |
| SaveManager | load_completed | success, slot_id |
| PlayerStats | health_changed | current, maximum |
| PlayerStats | mana_changed | current, maximum |
| PlayerStats | stamina_changed | current, maximum |
| PlayerStats | leveled_up | new_level |
| SkillBase | skill_activated | source |
| SkillBase | cooldown_ended | - |
| ItemBase | item_picked_up | player |
| EnemyBase | died | - |
| EnemyBase | damaged | amount |

### B. 枚举完整定义

```gdscript
# GameManager.GameState
enum GameState { MENU, CHARACTER_SELECT, PLAYING, PAUSED, GAME_OVER, VICTORY }

# SkillBase.SkillType
enum SkillType { OFFENSIVE, DEFENSIVE, CONTROL, SUPPORT }

# SkillBase.TargetType
enum TargetType { SELF, ENEMY, AREA, DIRECTION }

# ItemBase.ItemType
enum ItemType { WEAPON, ARMOR, ACCESSORY, CONSUMABLE, SPECIAL }

# ItemBase.Rarity
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

# EnemyBase.EnemyType
enum EnemyType { MELEE, RANGED, TANK, ELITE, BOSS }

# EnemyBase.AIState
enum AIState { IDLE, PATROL, CHASE, ATTACK, STUNNED, DEAD }

# LevelTheme.EnvironmentType
enum EnvironmentType { DUNGEON, FOREST, DESERT, ICE, VOLCANIC, VOID, CASTLE }
```
