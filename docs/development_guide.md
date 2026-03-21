# Void Hunter - 开发指南

**版本**: 1.0.0
**作者**: Void Hunter Team
**最后更新**: 2024

---

## 目录

1. [环境搭建](#1-环境搭建)
2. [代码规范](#2-代码规范)
3. [添加新角色](#3-添加新角色)
4. [添加新技能](#4-添加新技能)
5. [添加新道具](#5-添加新道具)
6. [添加新敌人](#6-添加新敌人)
7. [添加新关卡主题](#7-添加新关卡主题)
8. [调试工具使用](#8-调试工具使用)

---

## 1. 环境搭建

### 1.1 系统要求

| 项目 | 最低要求 | 推荐配置 |
|------|----------|----------|
| 操作系统 | Windows 10 / macOS 10.15 / Ubuntu 20.04 | 最新版本 |
| 内存 | 8GB | 16GB |
| 存储空间 | 5GB | 10GB |
| 显卡 | 支持OpenGL 3.3 | 支持Vulkan |

### 1.2 安装 Godot Engine

1. **下载 Godot**

   访问 [Godot 官网](https://godotengine.org/download) 下载 Godot 4.x 标准版：
   - Windows: `Godot_v4.x.x_stable_win64.exe`
   - macOS: `Godot_v4.x.x_stable_macos.universal.zip`
   - Linux: `Godot_v4.x.x_stable_linux.x86_64.zip`

2. **安装/解压**

   - Windows/macOS: 解压到任意目录
   - Linux: 解压并添加执行权限

   ```bash
   unzip Godot_v4.x.x_stable_linux.x86_64.zip
   chmod +x Godot_v4.x.x_stable_linux.x86_64
   ```

3. **启动 Godot**

   双击可执行文件或通过命令行启动。

### 1.3 克隆项目

```bash
# 克隆仓库
git clone https://github.com/your-org/void_hunter.git

# 进入项目目录
cd void_hunter
```

### 1.4 打开项目

1. 启动 Godot Engine
2. 点击 "Import" 按钮
3. 选择项目目录中的 `project.godot` 文件
4. 点击 "Import & Edit"

### 1.5 项目配置

首次打开项目后，建议进行以下配置：

1. **编辑器设置**
   - `Editor > Editor Settings > Text Editor > Completion`
     - 启用 Auto Brace Complete
     - 启用 Code Complete Delay (0.3s)

2. **版本控制**
   - `Editor > Editor Settings > Version Control`
     - 设置 Username 和 Email

3. **调试设置**
   - `Editor > Editor Settings > Run`
     - 启用 Auto Load Save

### 1.6 开发工具推荐

| 工具 | 用途 | 下载地址 |
|------|------|----------|
| VS Code | 代码编辑 | https://code.visualstudio.com/ |
| GDScript 插件 | 语法高亮 | VS Code 扩展 |
| Git | 版本控制 | https://git-scm.com/ |
| Aseprite | 像素画编辑 | https://www.aseprite.org/ |
| BFXR | 音效生成 | https://www.bfxr.net/ |

---

## 2. 代码规范

### 2.1 文件命名

```
场景文件: snake_case.tscn    # 例如: main_menu.tscn
脚本文件: snake_case.gd      # 例如: game_manager.gd
资源文件: snake_case.tres    # 例如: player_stats.tres
```

### 2.2 类命名

```gdscript
# 使用 PascalCase 命名类
class_name GameManager
class_name PlayerStats
class_name SkillBase
```

### 2.3 函数命名

```gdscript
# 使用 snake_case 命名函数
func get_player_stats() -> PlayerStats:
    pass

func calculate_damage(base: float) -> float:
    pass

# 信号回调函数以 _on_ 开头
func _on_enemy_died(enemy: Node) -> void:
    pass
```

### 2.4 变量命名

```gdscript
# 常量: SCREAMING_SNAKE_CASE
const MAX_HEALTH: float = 100.0
const DEFAULT_SPEED: float = 150.0

# 变量: snake_case
var current_health: float = 100.0
var enemy_count: int = 0

# 私有变量: _snake_case
var _is_initialized: bool = false
var _save_directory: String = ""

# 导出变量: 带类型注解
@export var debug_mode: bool = false
@export_range(0.0, 1.0) var volume: float = 1.0
```

### 2.5 信号命名

```gdscript
# 使用 snake_case，过去时或描述性名称
signal health_changed(current: float, maximum: float)
signal enemy_died(enemy: Node)
signal game_started
signal level_completed(level_index: int)
```

### 2.6 注释规范

```gdscript
## Void Hunter - 游戏管理器
## @description: 全局游戏状态管理和事件分发
## @author: Void Hunter Team
## @version: 1.0.0

extends Node

# =============================================================================
# 信号定义
# =============================================================================

## 游戏状态变化时触发
## @param old_state: 旧状态
## @param new_state: 新状态
signal game_state_changed(old_state: GameState, new_state: GameState)

# =============================================================================
# 常量定义
# =============================================================================

## 最大存档槽位数
const MAX_SAVE_SLOTS: int = 3

# =============================================================================
# 公共方法
# =============================================================================

## 开始新游戏
## @param character_id: 选择的角色ID
## @return: 是否成功开始
func start_game(character_id: String) -> bool:
    """
    开始新游戏，初始化游戏状态并加载关卡。
    
    Args:
        character_id: 角色的唯一标识符
        
    Returns:
        bool: 如果成功开始游戏返回 true
        
    Example:
        if GameManager.start_game("void_hunter"):
            print("游戏开始！")
    """
    # 实现代码...
    pass
```

### 2.7 代码结构模板

```gdscript
## 文件头注释
## @description: ...
## @author: ...
## @version: ...

extends Node
class_name MyClass

# =============================================================================
# 信号定义
# =============================================================================

signal my_signal(param: int)

# =============================================================================
# 枚举定义
# =============================================================================

enum MyEnum { VALUE_A, VALUE_B, VALUE_C }

# =============================================================================
# 常量定义
# =============================================================================

const MY_CONSTANT: int = 100

# =============================================================================
# 导出变量
# =============================================================================

@export var my_property: float = 1.0

# =============================================================================
# 公共变量
# =============================================================================

var public_var: String = ""

# =============================================================================
# 私有变量
# =============================================================================

var _private_var: bool = false

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
    pass

func _process(delta: float) -> void:
    pass

# =============================================================================
# 公共方法
# =============================================================================

func public_method() -> void:
    pass

# =============================================================================
# 私有方法
# =============================================================================

func _private_method() -> void:
    pass

# =============================================================================
# 信号回调
# =============================================================================

func _on_signal_received() -> void:
    pass
```

### 2.8 类型注解

```gdscript
# 始终使用类型注解
var health: float = 100.0
var player: Player = null
var enemies: Array[Enemy] = []

# 函数参数和返回值
func get_damage(target: Node) -> float:
    return 10.0

# 可空类型
var optional_value: Variant = null
```

---

## 3. 添加新角色

### 3.1 创建角色脚本

在 `src/characters/characters/` 目录下创建新文件：

```gdscript
# src/characters/characters/arcane_mage.gd
## Void Hunter - 奥术法师
## @description: 远程法术输出角色，擅长元素魔法
## @author: Your Name
## @version: 1.0.0

extends CharacterBase
class_name ArcaneMage

# =============================================================================
# 常量定义
# =============================================================================

## 奥术弹幕冷却时间
const ARCANE_BARRAGE_COOLDOWN: float = 8.0

## 奥术弹幕伤害
const ARCANE_BARRAGE_DAMAGE: float = 50.0

# =============================================================================
# 私有变量
# =============================================================================

var _arcane_barrage_timer: float = 0.0
var _arcane_projectiles: Array[Node] = []

# =============================================================================
# 生命周期方法
# =============================================================================

func _init():
    # 设置角色基本信息
    character_id = "arcane_mage"
    character_name = "奥术法师"
    description = "精通奥术魔法的法师，可以释放毁灭性的奥术弹幕"
    
    # 设置基础属性
    base_health = 80.0      # 较低的生命值
    base_mana = 100.0       # 较高的法力值
    base_stamina = 80.0
    base_attack = 8.0       # 较低的物理攻击
    base_defense = 3.0      # 较低的防御
    base_speed = 140.0      # 中等速度
    base_critical_chance = 0.1   # 较高的暴击率
    base_critical_damage = 1.8   # 较高的暴击伤害

func _process(delta: float) -> void:
    # 更新技能冷却
    if _arcane_barrage_timer > 0:
        _arcane_barrage_timer -= delta

# =============================================================================
# 公共方法
# =============================================================================

## 使用特殊能力：奥术弹幕
## 向四周发射多枚奥术飞弹
func use_special_ability() -> void:
    if not is_ability_ready():
        return
    
    _arcane_barrage_timer = ARCANE_BARRAGE_COOLDOWN
    
    # 发射12枚奥术飞弹
    var projectile_count: int = 12
    var angle_step: float = TAU / projectile_count
    
    for i in range(projectile_count):
        var angle: float = i * angle_step
        var direction: Vector2 = Vector2.from_angle(angle)
        _spawn_arcane_projectile(direction)
    
    ability_used.emit("arcane_barrage")

## 检查特殊能力是否就绪
func is_ability_ready() -> bool:
    return _arcane_barrage_timer <= 0

## 获取能力冷却时间
func get_ability_cooldown() -> float:
    return _arcane_barrage_timer

## 获取解锁条件
static func get_unlock_condition() -> Dictionary:
    return {
        "type": "skill_use",
        "value": 500,
        "description": "累计使用技能500次"
    }

# =============================================================================
# 私有方法
# =============================================================================

func _spawn_arcane_projectile(direction: Vector2) -> void:
    var projectile: Node = ObjectPool.get_instance(
        preload("res://scenes/projectiles/arcane_bullet.tscn")
    )
    projectile.initialize(
        _owner.global_position,
        direction,
        ARCANE_BARRAGE_DAMAGE
    )
    _arcane_projectiles.append(projectile)
```

### 3.2 创建角色场景

1. 在 `scenes/characters/` 创建新场景 `arcane_mage.tscn`
2. 根节点使用 `CharacterBody2D`
3. 添加必要的子节点：
   - `Sprite2D`: 角色精灵
   - `CollisionShape2D`: 碰撞形状
   - `AnimationPlayer`: 动画播放器

### 3.3 创建角色资源

在 `resources/characters/` 创建 `arcane_mage.tres`：

```gdscript
[gd_resource type="Resource" load_steps=2 format=3 uid="uid://..."]

[resource]
script = ExtResource("uid://...arcane_mage.gd")
character_id = "arcane_mage"
character_name = "奥术法师"
description = "精通奥术魔法的法师"
base_health = 80.0
base_mana = 100.0
portrait = ExtResource("uid://...arcane_mage_portrait.png")
```

### 3.4 注册角色

在 `GameManager` 中添加角色注册：

```gdscript
# src/autoload/game_manager.gd

const CHARACTER_SCENES: Dictionary = {
    "void_hunter": preload("res://scenes/characters/void_hunter.tscn"),
    "arcane_mage": preload("res://scenes/characters/arcane_mage.tscn"),
    # 添加新角色
}

const CHARACTER_RESOURCES: Dictionary = {
    "void_hunter": preload("res://resources/characters/void_hunter.tres"),
    "arcane_mage": preload("res://resources/characters/arcane_mage.tres"),
    # 添加新角色
}
```

---

## 4. 添加新技能

### 4.1 创建技能脚本

在 `src/skills/skills/` 对应目录下创建：

```gdscript
# src/skills/skills/offensive/chain_lightning.gd
## Void Hunter - 连锁闪电
## @description: 释放一道连锁闪电，在敌人之间弹跳
## @author: Your Name
## @version: 1.0.0

extends SkillBase
class_name ChainLightning

# =============================================================================
# 常量定义
# =============================================================================

## 最大连锁次数
const MAX_CHAINS: int = 5

## 连锁范围
const CHAIN_RANGE: float = 150.0

## 每次连锁伤害衰减
const DAMAGE_DECAY: float = 0.8

# =============================================================================
# 私有变量
# =============================================================================

var _current_chains: int = 0
var _chained_enemies: Array[Node] = []

# =============================================================================
# 初始化
# =============================================================================

func _init():
    skill_id = "chain_lightning"
    skill_name = "连锁闪电"
    description = "释放一道闪电，在敌人之间弹跳，每次弹跳伤害降低20%"
    skill_type = SkillType.OFFENSIVE
    target_type = TargetType.ENEMY
    max_level = 5
    cooldown = 3.0
    mana_cost = 25.0
    damage = 30.0
    range = 300.0
    
    # 设置图标
    icon = preload("res://assets/images/skills/chain_lightning.png")

# =============================================================================
# 公共方法
# =============================================================================

## 激活技能
func activate(source: Node, target: Node = null) -> void:
    super.activate(source, target)
    
    if target == null:
        target = _find_nearest_enemy(source)
    
    if target == null:
        return
    
    _current_chains = 0
    _chained_enemies.clear()
    _chain_to_target(source, target, damage)
    
    skill_activated.emit(source)

## 获取技能描述
func get_description() -> String:
    var desc: String = description
    desc += "\n\n当前等级: %d" % level
    desc += "\n伤害: %.0f" % damage
    desc += "\n连锁次数: %d" % _get_max_chains()
    desc += "\n冷却: %.1f秒" % cooldown
    desc += "\n法力消耗: %.0f" % mana_cost
    
    if level < max_level:
        desc += "\n\n下一级:"
        desc += "\n伤害: %.0f" % (damage * 1.2)
        desc += "\n连锁次数: %d" % (_get_max_chains() + 1)
    
    return desc

# =============================================================================
# 私有方法
# =============================================================================

func _chain_to_target(source: Node, target: Node, dmg: float) -> void:
    if _current_chains >= _get_max_chains():
        return
    
    if target == null or not is_instance_valid(target):
        return
    
    _chained_enemies.append(target)
    _current_chains += 1
    
    # 应用伤害
    if target.has_method("apply_damage"):
        target.apply_damage(dmg, source)
    
    # 创建闪电效果
    _create_lightning_effect(source.global_position, target.global_position)
    
    # 寻找下一个目标
    var next_target: Node = _find_next_chain_target(target)
    if next_target != null:
        # 延迟连锁，创造视觉效果
        await get_tree().create_timer(0.1).timeout
        _chain_to_target(target, next_target, dmg * DAMAGE_DECAY)

func _find_nearest_enemy(source: Node) -> Node:
    var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
    var nearest: Node = null
    var nearest_dist: float = INF
    
    for enemy in enemies:
        var dist: float = source.global_position.distance_to(enemy.global_position)
        if dist < range and dist < nearest_dist:
            nearest = enemy
            nearest_dist = dist
    
    return nearest

func _find_next_chain_target(current: Node) -> Node:
    var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
    var nearest: Node = null
    var nearest_dist: float = INF
    
    for enemy in enemies:
        if enemy in _chained_enemies:
            continue
        
        var dist: float = current.global_position.distance_to(enemy.global_position)
        if dist < CHAIN_RANGE and dist < nearest_dist:
            nearest = enemy
            nearest_dist = dist
    
    return nearest

func _get_max_chains() -> int:
    return MAX_CHAINS + (level - 1)

func _create_lightning_effect(from: Vector2, to: Vector2) -> void:
    # 创建闪电视觉效果
    var effect: Node = ObjectPool.get_instance(
        preload("res://scenes/effects/lightning_effect.tscn")
    )
    effect.initialize(from, to)

func _apply_level_effects() -> void:
    # 每级增加伤害和连锁次数
    damage = 30.0 * (1.0 + (level - 1) * 0.2)
    cooldown = 3.0 - (level - 1) * 0.2
    
    match level:
        5:
            # 5级觉醒：不再衰减伤害
            DAMAGE_DECAY = 1.0
```

### 4.2 注册技能

在 `SkillManager` 或技能注册表中添加：

```gdscript
# src/skills/skill_registry.gd (如果存在)
# 或在 SkillManager 中

const SKILL_PREFABS: Dictionary = {
    "chain_lightning": preload("res://src/skills/skills/offensive/chain_lightning.gd"),
    # 其他技能...
}
```

---

## 5. 添加新道具

### 5.1 创建道具脚本

在 `src/items/items/` 目录下创建：

```gdscript
# src/items/items/weapon_thunder_staff.gd
## Void Hunter - 雷霆法杖
## @description: 增强闪电技能的传说武器
## @author: Your Name
## @version: 1.0.0

extends ItemBase
class_name WeaponThunderStaff

# =============================================================================
# 初始化
# =============================================================================

func _init():
    item_id = "weapon_thunder_staff"
    item_name = "雷霆法杖"
    description = "蕴含雷电之力的传说法杖，大幅增强闪电类技能"
    item_type = ItemType.WEAPON
    rarity = Rarity.LEGENDARY
    max_stack = 1
    
    # 道具效果
    effects = {
        "lightning_damage_percent": 0.5,   # 闪电伤害+50%
        "chain_count_bonus": 2,            # 连锁次数+2
        "mana_cost_percent": -0.2          # 法力消耗-20%
    }
    
    # 设置图标
    icon = preload("res://assets/images/items/thunder_staff.png")

# =============================================================================
# 生命周期方法
# =============================================================================

## 拾取时应用效果
func on_pickup(player: Node) -> void:
    super.on_pickup(player)
    
    if player == null:
        return
    
    # 获取玩家属性
    var stats: PlayerStats = player.stats
    if stats == null:
        return
    
    # 应用闪电伤害加成（通过信号通知技能系统）
    player.skill_manager.add_skill_bonus("lightning", "damage_percent", 0.5)
    player.skill_manager.add_skill_bonus("lightning", "chain_count", 2)
    
    # 应用法力消耗减少
    stats.add_percent_bonus("mana", -0.2)

## 丢弃时移除效果
func on_drop(player: Node) -> void:
    super.on_drop(player)
    
    if player == null:
        return
    
    var stats: PlayerStats = player.stats
    if stats == null:
        return
    
    # 移除效果
    player.skill_manager.remove_skill_bonus("lightning", "damage_percent", 0.5)
    player.skill_manager.remove_skill_bonus("lightning", "chain_count", 2)
    stats.add_percent_bonus("mana", 0.2)

## 获取效果描述
func get_effects_description() -> String:
    return """
    [color=yellow]闪电伤害 +50%[/color]
    [color=yellow]连锁次数 +2[/color]
    [color=cyan]法力消耗 -20%[/color]
    
    [i]套装效果：同时装备雷电系技能时，触发时有几率召唤雷暴[/i]
    """
```

### 5.2 注册道具

```gdscript
# src/items/item_registry.gd

func _ready() -> void:
    # 注册所有道具
    _register_item(WeaponThunderStaff.new())
    # 其他道具...
```

---

## 6. 添加新敌人

### 6.1 创建敌人脚本

在 `src/enemies/` 目录下创建：

```gdscript
# src/enemies/enemy_necromancer.gd
## Void Hunter - 死灵法师
## @description: 可以召唤骷髅的精英敌人
## @author: Your Name
## @version: 1.0.0

extends EnemyBase
class_name EnemyNecromancer

# =============================================================================
# 常量定义
# =============================================================================

## 召唤冷却时间
const SUMMON_COOLDOWN: float = 5.0

## 单次召唤数量
const SUMMON_COUNT: int = 3

## 召唤距离
const SUMMON_RANGE: float = 100.0

# =============================================================================
# 导出变量
# =============================================================================

## 骷髅场景
@export var skeleton_scene: PackedScene

# =============================================================================
# 私有变量
# =============================================================================

var _summon_timer: float = 0.0
var _summoned_skeletons: Array[Node] = []

# =============================================================================
# 初始化
# =============================================================================

func _init():
    enemy_id = "necromancer"
    enemy_name = "死灵法师"
    enemy_type = EnemyType.ELITE
    
    # 基础属性
    base_health = 150.0
    base_damage = 15.0
    base_speed = 60.0
    experience_value = 100
    
    # AI 配置
    detection_range = 250.0
    attack_range = 200.0
    
    # 加载骷髅场景
    skeleton_scene = preload("res://scenes/enemies/skeleton.tscn")

func _ready() -> void:
    super._ready()
    
    # 设置 AI 行为
    _setup_ai_behavior()

# =============================================================================
# 公共方法
# =============================================================================

## 执行攻击
func attack() -> void:
    if _summon_timer > 0:
        # 发射暗影弹
        _fire_shadow_bolt()
    else:
        # 召唤骷髅
        _summon_skeletons()
        _summon_timer = SUMMON_COOLDOWN

## 死亡处理
func die() -> void:
    # 召唤的骷髅也会死亡
    for skeleton in _summoned_skeletons:
        if is_instance_valid(skeleton):
            skeleton.die()
    
    super.die()

# =============================================================================
# 私有方法
# =============================================================================

func _setup_ai_behavior() -> void:
    # 自定义 AI 行为：保持距离并召唤
    # 可以使用 EnemyAIBase 的行为树或状态机
    pass

func _summon_skeletons() -> void:
    for i in range(SUMMON_COUNT):
        var angle: float = randf() * TAU
        var spawn_pos: Vector2 = global_position + Vector2.from_angle(angle) * SUMMON_RANGE
        
        var skeleton: Node = ObjectPool.get_instance(skeleton_scene, get_parent())
        skeleton.global_position = spawn_pos
        skeleton.initialize({
            "health_multiplier": 0.5  # 召唤的骷髅较弱
        })
        
        _summoned_skeletons.append(skeleton)
        
        # 召唤特效
        _create_summon_effect(spawn_pos)

func _fire_shadow_bolt() -> void:
    if target == null:
        return
    
    var direction: Vector2 = (target.global_position - global_position).normalized()
    var bolt: Node = ObjectPool.get_instance(
        preload("res://scenes/projectiles/shadow_bolt.tscn"),
        get_parent()
    )
    bolt.initialize(global_position, direction, base_damage)

func _create_summon_effect(position: Vector2) -> void:
    # 创建召唤特效
    var effect: Node = ObjectPool.get_instance(
        preload("res://scenes/effects/summon_circle.tscn"),
        get_parent()
    )
    effect.global_position = position

func _process(delta: float) -> void:
    super._process(delta)
    
    # 更新召唤冷却
    if _summon_timer > 0:
        _summon_timer -= delta
```

### 6.2 创建敌人场景

1. 在 `scenes/enemies/` 创建 `necromancer.tscn`
2. 配置碰撞形状、动画等
3. 添加到关卡主题的敌人池

---

## 7. 添加新关卡主题

### 7.1 创建主题资源

在编辑器中创建新的 `LevelTheme` 资源：

1. 右键 `resources/themes/` -> New Resource -> LevelTheme
2. 保存为 `ocean_theme.tres`

### 7.2 配置主题属性

```gdscript
# 在编辑器中配置或在代码中设置

# 基本信息
theme_id = "ocean"
theme_name = "深海遗迹"
environment_type = LevelTheme.EnvironmentType.VOID
description = "古老的海底遗迹，隐藏着深海的秘密"

# 视觉配置
background_color = Color(0.02, 0.05, 0.15)  # 深蓝色
ambient_light_color = Color(0.1, 0.2, 0.4)
ambient_light_energy = 0.3

# 敌人配置
enemy_pool = [
    preload("res://scenes/enemies/fish_soldier.tscn"),
    preload("res://scenes/enemies/jellyfish.tscn"),
    preload("res://scenes/enemies/seahorse_archer.tscn")
]
boss_pool = [
    preload("res://scenes/enemies/kraken.tscn")
]

# 道具配置
item_pool = [
    "trident",
    "coral_armor",
    "pearl_necklace"
]
item_rarity_weights = {
    0: 40,  # Common
    1: 35,  # Uncommon
    2: 18,  # Rare
    3: 5,   # Epic
    4: 2    # Legendary
}

# 难度配置
base_difficulty = 1.3
difficulty_growth = 0.15
min_level = 8
max_level = 12
```

### 7.3 创建主题瓦片集

1. 创建新的 TileSet 资源
2. 添加深海主题的瓦片：
   - 地板瓦片（珊瑚、沙地、石板等）
   - 墙壁瓦片（珊瑚墙、岩石等）
   - 装饰瓦片（海草、贝壳、沉船碎片等）

### 7.4 注册主题

```gdscript
# src/levels/level_manager.gd

const LEVEL_THEMES: Array[LevelTheme] = [
    preload("res://resources/themes/dungeon_theme.tres"),
    preload("res://resources/themes/forest_theme.tres"),
    # 添加新主题
    preload("res://resources/themes/ocean_theme.tres")
]
```

---

## 8. 调试工具使用

### 8.1 启用调试模式

在 `GameManager` 中启用调试：

```gdscript
# 项目设置或代码中
GameManager.debug_mode = true
```

### 8.2 调试快捷键

| 快捷键 | 功能 |
|--------|------|
| `F3` | 显示/隐藏调试信息 |
| `F5` | 快速存档 |
| `F9` | 快速读档 |
| `Ctrl+1` | 无敌模式 |
| `Ctrl+2` | 无限法力 |
| `Ctrl+3` | 跳过当前波次 |
| `Ctrl+4` | 增加经验值1000 |
| `Ctrl+5` | 升级 |
| `Ctrl+L` | 切换关卡 |

### 8.3 调试控制台

在游戏中按 `~` 打开调试控制台：

```
> help                    # 显示所有命令
> god                     # 无敌模式
> give item_id            # 获得道具
> add_skill skill_id      # 添加技能
> spawn enemy_id count    # 生成敌人
> set_level level_index   # 切换关卡
> kill_all                # 清除所有敌人
> show_collisions         # 显示碰撞框
> show_ai                 # 显示AI状态
```

### 8.4 使用 DebugTools 类

```gdscript
# src/utils/debug_tools.gd

# 输出调试日志
DebugTools.log_debug("敌人数量: %d" % enemy_count, "Combat")

# 绘制调试圆圈（检测范围等）
DebugTools.draw_debug_circle(self, global_position, detection_range, Color.RED)

# 绘制调试线条
DebugTools.draw_debug_line(self, from_pos, to_pos, Color.YELLOW)

# 生成调试标记
DebugTools.spawn_debug_marker(target_position, 2.0)
```

### 8.5 性能分析

使用 Godot 内置的性能分析工具：

1. **帧时间分析**
   - `Debugger > Monitors` 查看实时性能数据
   - 关注 Frame Time, Physics Time, Process Time

2. **内存分析**
   - `Debugger > Monitors > Memory` 查看内存使用

3. **对象计数**
   - 检查对象池使用情况
   - 确保对象正确回收

### 8.6 常见调试场景

#### 8.6.1 调试技能效果

```gdscript
func activate(source: Node, target: Node = null) -> void:
    if GameManager.debug_mode:
        print("[DEBUG] 技能激活: %s, 来源: %s, 目标: %s" % [skill_id, source.name, target])
        DebugTools.spawn_debug_marker(source.global_position, 1.0)
    
    # 正常技能逻辑...
```

#### 8.6.2 调试敌人AI

```gdscript
func _process(delta: float) -> void:
    if GameManager.debug_mode:
        # 显示检测范围
        DebugTools.draw_debug_circle(self, global_position, detection_range, Color(1, 0, 0, 0.3))
        # 显示攻击范围
        DebugTools.draw_debug_circle(self, global_position, attack_range, Color(1, 1, 0, 0.3))
        # 显示到目标的连线
        if target:
            DebugTools.draw_debug_line(self, global_position, target.global_position, Color.GREEN)
```

#### 8.6.3 调试碰撞检测

```gdscript
func _draw() -> void:
    if GameManager.debug_mode:
        # 绘制碰撞形状
        var shape: CollisionShape2D = $CollisionShape2D
        if shape and shape.shape:
            draw_circle(shape.position, shape.shape.radius, Color(0, 1, 0, 0.3))
```

---

## 附录

### A. 项目模板结构

```
new_feature/
├── src/
│   └── feature_name/
│       ├── feature_base.gd
│       └── feature_impl.gd
├── scenes/
│   └── feature_name/
│       └── feature.tscn
├── resources/
│   └── feature_name/
│       └── feature.tres
└── assets/
    └── feature_name/
        └── images/
```

### B. Git 工作流程

```bash
# 创建功能分支
git checkout -b feature/new-character-arcane-mage

# 提交更改
git add .
git commit -m "feat: add Arcane Mage character"

# 推送分支
git push origin feature/new-character-arcane-mage

# 创建 Pull Request
```

### C. 代码审查清单

- [ ] 代码符合命名规范
- [ ] 添加了必要的注释
- [ ] 类型注解完整
- [ ] 无编译警告
- [ ] 无调试代码残留
- [ ] 性能考虑（对象池使用等）
- [ ] 信号连接正确断开
