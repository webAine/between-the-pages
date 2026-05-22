class_name DayResultsUI
extends CanvasLayer

signal next_day_pressed

var _day_label: Label
var _customers_label: Label
var _money_label: Label
var _reputation_label: Label


func _ready() -> void:
	layer = 4
	_build_ui()
	visible = false


func show_results(day: int, satisfied: int, total: int, money_earned: int, reputation_delta: int) -> void:
	_day_label.text = "День %d окончен" % day
	_customers_label.text = "Покупатели: %d из %d довольны" % [satisfied, total]
	_money_label.text = "Заработано: +%d монет" % money_earned

	if reputation_delta > 0:
		_reputation_label.text = "Репутация: +%d" % reputation_delta
	elif reputation_delta < 0:
		_reputation_label.text = "Репутация: %d" % reputation_delta
	else:
		_reputation_label.text = "Репутация: без изменений"

	visible = true


func _build_ui() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var panel := ColorRect.new()
	panel.color = Color(0.12, 0.09, 0.07, 1.0)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.size = Vector2(480, 300)
	panel.offset_left = -240
	panel.offset_right = 240
	panel.offset_top = -150
	panel.offset_bottom = 150
	add_child(panel)

	_day_label = Label.new()
	_day_label.position = Vector2(20, 20)
	_day_label.size = Vector2(440, 40)
	panel.add_child(_day_label)

	var sep := ColorRect.new()
	sep.color = Color(0.3, 0.25, 0.2)
	sep.position = Vector2(20, 68)
	sep.size = Vector2(440, 1)
	panel.add_child(sep)

	_customers_label = Label.new()
	_customers_label.position = Vector2(20, 85)
	_customers_label.size = Vector2(440, 30)
	panel.add_child(_customers_label)

	_money_label = Label.new()
	_money_label.position = Vector2(20, 125)
	_money_label.size = Vector2(440, 30)
	panel.add_child(_money_label)

	_reputation_label = Label.new()
	_reputation_label.position = Vector2(20, 165)
	_reputation_label.size = Vector2(440, 30)
	panel.add_child(_reputation_label)

	var btn := Button.new()
	btn.text = "Следующий день →"
	btn.position = Vector2(20, 240)
	btn.size = Vector2(440, 45)
	btn.pressed.connect(_on_next_pressed)
	panel.add_child(btn)


func _on_next_pressed() -> void:
	visible = false
	next_day_pressed.emit()
