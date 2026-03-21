## Void Hunter - 输入映射配置
## @description: 定义项目所需的输入映射（需要在项目设置中配置）
## @author: Void Hunter Team
## @version: 1.0.0

## 输入映射配置说明
## 
## 请在 Godot 编辑器中打开 项目 -> 项目设置 -> 输入映射
## 添加以下输入动作：
##
## [移动控制]
## ui_up      - W, 上箭头
## ui_down    - S, 下箭头
## ui_left    - A, 左箭头
## ui_right   - D, 右箭头
##
## [战斗控制]
## attack     - 鼠标左键, 空格
## dash       - Shift, 鼠标右键
## skill_1    - Q
## skill_2    - E
## skill_3    - R
##
## [系统控制]
## inventory  - I, Tab
## pause      - Escape
## toggle_auto_fire - T
##
## [调试快捷键] (仅在调试模式)
## debug_god_mode     - F1
## debug_heal         - F2
## debug_add_exp      - F3
## debug_level_up     - F4
## debug_spawn_enemy  - F5
## debug_clear_enemies - F6
## debug_kill_all     - F7
## debug_next_wave    - F8
## debug_add_gold     - F9
## debug_toggle_info  - F10

extends Node

# =============================================================================
# 输入映射定义（用于动态添加）
# =============================================================================

const INPUT_MAPPINGS: Dictionary = {
	# 移动
	"ui_up": [KEY_W, KEY_UP],
	"ui_down": [KEY_S, KEY_DOWN],
	"ui_left": [KEY_A, KEY_LEFT],
	"ui_right": [KEY_D, KEY_RIGHT],
	
	# 战斗
	"attack": [MOUSE_BUTTON_LEFT, KEY_SPACE],
	"dash": [KEY_SHIFT, MOUSE_BUTTON_RIGHT],
	"skill_1": [KEY_Q],
	"skill_2": [KEY_E],
	"skill_3": [KEY_R],
	
	# 系统
	"inventory": [KEY_I, KEY_TAB],
	"pause": [KEY_ESCAPE],
	"toggle_auto_fire": [KEY_T],
	
	# 调试
	"debug_god_mode": [KEY_F1],
	"debug_heal": [KEY_F2],
	"debug_add_exp": [KEY_F3],
	"debug_level_up": [KEY_F4],
	"debug_spawn_enemy": [KEY_F5],
	"debug_clear_enemies": [KEY_F6],
	"debug_kill_all": [KEY_F7],
	"debug_next_wave": [KEY_F8],
	"debug_add_gold": [KEY_F9],
	"debug_toggle_info": [KEY_F10]
}


## 动态设置输入映射（运行时调用）
func setup_input_mappings() -> void:
	"""
	动态设置输入映射
	注意：推荐在项目设置中手动配置，此方法仅作为备选方案
	"""
	for action_name in INPUT_MAPPINGS:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			
			for key_code in INPUT_MAPPINGS[action_name]:
				var event: InputEvent
				
				if key_code is int and key_code >= KEY_SPACE:
					# 键盘事件
					event = InputEventKey.new()
					event.keycode = key_code
				elif key_code is int:
					# 鼠标按钮事件
					event = InputEventMouseButton.new()
					event.button_index = key_code
				
				if event:
					InputMap.action_add_event(action_name, event)
