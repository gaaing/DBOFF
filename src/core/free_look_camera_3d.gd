class_name FreeLookCamera3D
extends Camera3D

## Free Look Camera 3D (Dragon Ball Online Scene Inspection Controller)
## 提供大世界漫游、高程地形检验与场景物件巡检的平滑自由观察摄像机。
## 控制键位：
##   - 鼠标右键长按拖拽：旋转视角 (Yaw / Pitch)
##   - W / A / S / D：前后左右平移
##   - Q / E：下降 / 上升
##   - Shift：三倍加速巡航
##   - 滚轮：调校航速

@export var move_speed: float = 30.0
@export var sprint_multiplier: float = 3.0
@export var mouse_sensitivity: float = 0.003

var _yaw: float = 0.0
var _pitch: float = 0.0
var _is_rmb_pressed: bool = false


func _ready() -> void:
	_yaw = rotation.y
	_pitch = rotation.x


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_is_rmb_pressed = event.pressed
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _is_rmb_pressed else Input.MOUSE_MODE_VISIBLE
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			move_speed = clampf(move_speed * 1.15, 2.0, 300.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			move_speed = clampf(move_speed / 1.15, 2.0, 300.0)

	elif event is InputEventMouseMotion and _is_rmb_pressed:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch = clampf(_pitch - event.relative.y * mouse_sensitivity, -1.5, 1.5)
		rotation = Vector3(_pitch, _yaw, 0.0)


func _process(delta: float) -> void:
	var input_vec := Vector3.ZERO

	if Input.is_key_pressed(KEY_W):
		input_vec += -global_transform.basis.z
	if Input.is_key_pressed(KEY_S):
		input_vec += global_transform.basis.z
	if Input.is_key_pressed(KEY_A):
		input_vec += -global_transform.basis.x
	if Input.is_key_pressed(KEY_D):
		input_vec += global_transform.basis.x
	if Input.is_key_pressed(KEY_E):
		input_vec += Vector3.UP
	if Input.is_key_pressed(KEY_Q):
		input_vec += Vector3.DOWN

	if input_vec != Vector3.ZERO:
		var speed := move_speed
		if Input.is_key_pressed(KEY_SHIFT):
			speed *= sprint_multiplier
		global_position += input_vec.normalized() * speed * delta
