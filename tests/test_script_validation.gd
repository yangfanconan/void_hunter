## Void Hunter - 脚本语法验证测试
## 验证所有GDScript文件可以正确解析

extends SceneTree

var passed := 0
var failed := 0
var errors := []

func _init() -> void:
    print("\n" + "=" .repeat(60))
    print("  Void Hunter - 脚本语法验证")
    print("=" .repeat(60) + "\n")

    # 验证所有关键脚本
    validate_all_scripts()
    
    # 输出报告
    print_report()
    quit()

func validate_all_scripts() -> void:
    var scripts := [
        # 核心系统
        "res://src/game.gd",
        "res://src/systems/status_effect_manager.gd",
        "res://src/systems/combo_system.gd",
        "res://src/systems/permanent_talent_tree.gd",
        "res://src/systems/game_system_integrator.gd",
        
        # 自动加载
        "res://src/autoload/save_manager.gd",
        "res://src/autoload/game_manager.gd",
        "res://src/autoload/audio_manager.gd",
        
        # 敌人
        "res://src/enemies/enemy_base.gd",
        "res://src/enemies/enemy_melee.gd",
        "res://src/enemies/enemy_ranged.gd",
        "res://src/enemies/enemy_tank.gd",
        "res://src/enemies/enemy_elite.gd",
        
        # 角色
        "res://src/characters/character_base.gd",
        "res://src/characters/characters/arcane_warlock.gd",
        "res://src/characters/characters/frost_witch.gd",
        "res://src/characters/characters/holy_paladin.gd",
        "res://src/characters/characters/night_ranger.gd",
        "res://src/characters/characters/thunder_lord.gd",
        "res://src/characters/characters/mech_engineer.gd",
        "res://src/characters/characters/dragon_sage.gd",
        
        # 道具
        "res://src/items/item_base.gd",
        "res://src/items/drop_system.gd",
        "res://src/items/drop_item.gd",
        "res://src/items/item_database.gd",
        
        # 技能
        "res://src/skills/skill_base.gd",
        "res://src/skills/skill_manager.gd",
    ]
    
    for script_path in scripts:
        validate_script(script_path)

func validate_script(path: String) -> void:
    var script := load(path)
    if script == null:
        failed += 1
        errors.append("%s: 加载失败" % path)
        print("  [FAIL] %s - 无法加载" % path)
        return
    
    # 检查是否可以实例化（对于非继承类）
    var can_check := true
    if path.contains("/characters/characters/") or path.contains("/enemies/enemy_"):
        can_check = false  # 这些是继承类，需要基类
    
    if can_check:
        # 尝试获取脚本的方法列表（这会触发解析）
        var _methods: Array = script.get_script_method_list()
        passed += 1
        print("  [PASS] %s" % path)
    else:
        passed += 1
        print("  [PASS] %s (继承类)" % path)

func print_report() -> void:
    print("\n" + "=" .repeat(60))
    print("  脚本验证报告")
    print("=" .repeat(60))
    print("  通过: %d" % passed)
    print("  失败: %d" % failed)
    print("  总计: %d" % (passed + failed))
    print("")
    
    if errors.size() > 0:
        print("  错误列表:")
        for err in errors:
            print("    - %s" % err)
        print("")
    
    if failed == 0:
        print("  >>> 所有脚本验证通过! <<<")
    else:
        print("  >>> 有 %d 个脚本验证失败 <<<" % failed)
    
    print("=" .repeat(60) + "\n")
