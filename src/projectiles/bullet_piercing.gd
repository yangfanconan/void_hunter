## Void Hunter - 穿透子弹
## @description: 可以穿透多个敌人的子弹
## @author: Void Hunter Team
## @version: 1.0.0

extends BulletBase
class_name BulletPiercing

# =============================================================================
# 导出变量
# =============================================================================

## 穿透后的伤害衰减
@export_range(0.0, 1.0) var damage_reduction_per_pierce: float = 0.2

## 穿透后的速度衰减
@export_range(0.0, 1.0) var speed_reduction_per_pierce: float = 0.1

## 是否穿透障碍物
@export var pierce_obstacles: bool = false

## 穿透时的视觉反馈
@export var flash_on_pierce: bool = true

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化
	"""
	bullet_type = BulletType.PIERCING
	piercing = true
	super._ready()

# =============================================================================
# 重写方法
# =============================================================================

func _apply_damage_to_target(target: Node) -> void:
	"""
	对目标造成伤害，应用穿透衰减
	@param target: 目标节点
	"""
	# 计算当前伤害（考虑穿透衰减）
	var current_damage: float = damage * pow(1.0 - damage_reduction_per_pierce, pierce_count)
	
	if target.has_method("take_damage"):
		target.take_damage(current_damage, self)
		
		# 应用击退
		if target.has_method("_apply_knockback"):
			target._apply_knockback(global_position)
		elif "velocity" in target:
			target.velocity += direction * knockback_force
	
	# 穿透效果
	_on_pierce()


func _handle_obstacle_collision(obstacle: Node) -> void:
	"""
	处理障碍物碰撞
	@param obstacle: 障碍物节点
	"""
	if pierce_obstacles:
		_on_pierce()
	else:
		destroy()

# =============================================================================
# 私有方法
# =============================================================================

func _on_pierce() -> void:
	"""
	穿透时调用的方法
	"""
	pierce_count += 1
	
	# 速度衰减
	speed *= (1.0 - speed_reduction_per_pierce)
	
	# 视觉反馈
	if flash_on_pierce:
		_flash_effect()
	
	# 检查是否达到最大穿透
	if pierce_count >= max_pierce_count:
		destroy()


func _flash_effect() -> void:
	"""
	穿透时的闪烁效果
	"""
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.05)
	tween.tween_property(self, "modulate", Color(1, 1, 0.5), 0.1)
