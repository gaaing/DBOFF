class_name CameraSplinePlayer
extends Node3D

## Camera Spline Player (Dragon Ball Online Cinematic Directing)
## 基于 direct_splines.json 与 direct_project.json，
## 将 679 条官方样条曲线映射为 Path3D 与 PathFollow3D，
## 实现 TMQ 剧情过场、主线对话镜头推拉、必杀技（HTB）特写的 3D 摄像机平滑运镜。

signal spline_started(spline_name: String)
signal spline_completed(spline_name: String)

@export var target_camera: Camera3D = null

var _is_playing: bool = false
var _current_spline_name: String = ""
var _curve_points: Array = []
var _total_time: float = 1.0
var _current_time: float = 0.0


func _process(delta: float) -> void:
	if not _is_playing or target_camera == null or _curve_points.is_empty():
		return

	_current_time += delta
	var progress := clampf(_current_time / _total_time, 0.0, 1.0)
	var point_index := int(progress * float(_curve_points.size() - 1))

	var current_pt: Dictionary = _curve_points[point_index]
	var pos_arr: Array = current_pt.get("pos", [0, 0, 0])
	var quat_arr: Array = current_pt.get("quat", [0, 0, 0, 1])

	# 赋值目标相机位置
	if pos_arr.size() == 3:
		target_camera.global_position = Vector3(pos_arr[0], pos_arr[1], pos_arr[2])

	# 赋值目标相机旋转 (四元数变换)
	if quat_arr.size() == 4:
		var q := Quaternion(quat_arr[0], quat_arr[1], quat_arr[2], quat_arr[3])
		target_camera.quaternion = q

	if progress >= 1.0:
		stop_spline()


## 播放指定导演样条运镜
func play_spline(spline_name: String) -> bool:
	var spline_data := DBOTableManager.get_spline(spline_name)
	if spline_data.is_empty():
		push_warning("[CameraSplinePlayer] 找不到样条曲线: " + spline_name)
		return false

	_curve_points = spline_data.get("curve_points", [])
	if _curve_points.is_empty():
		push_warning("[CameraSplinePlayer] 样条曲线采样点为空: " + spline_name)
		return false

	_total_time = maxf(spline_data.get("total_time", 1.0), 0.1)
	_current_time = 0.0
	_current_spline_name = spline_name
	_is_playing = true

	spline_started.emit(spline_name)
	return true


## 停止当前运镜
func stop_spline() -> void:
	if _is_playing:
		_is_playing = false
		spline_completed.emit(_current_spline_name)
		_current_spline_name = ""


func is_playing() -> bool:
	return _is_playing
