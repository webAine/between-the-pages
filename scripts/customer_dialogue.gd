class_name CustomerDialogue
extends CanvasLayer

signal bring_book_requested
signal next_customer_requested

var _portrait: ColorRect
var _name_label: Label
var _dialogue_label: Label
var _request_label: Label
var _bring_button: Button
var _next_button: Button


func _ready() -> void:
	layer = 2
	_build_ui()


func _build_ui() -> void:
	var panel := ColorRect.new()
	panel.color = Color(0.10, 0.07, 0.06, 1.0)
	panel.position = Vector2(960, 0)
	panel.size = Vector2(320, 720)
	add_child(panel)

	var divider := ColorRect.new()
	divider.color = Color(0.28, 0.20, 0.13)
	divider.position = Vector2(0, 0)
	divider.size = Vector2(3, 720)
	panel.add_child(divider)

	_portrait = ColorRect.new()
	_portrait.color = Color(0.18, 0.13, 0.09)
	_portrait.position = Vector2(20, 20)
	_portrait.size = Vector2(280, 200)
	panel.add_child(_portrait)

	_name_label = Label.new()
	_name_label.position = Vector2(20, 232)
	_name_label.size = Vector2(280, 28)
	panel.add_child(_name_label)

	_dialogue_label = Label.new()
	_dialogue_label.position = Vector2(20, 268)
	_dialogue_label.size = Vector2(280, 130)
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	panel.add_child(_dialogue_label)

	var sep := ColorRect.new()
	sep.color = Color(0.28, 0.20, 0.13)
	sep.position = Vector2(20, 408)
	sep.size = Vector2(280, 1)
	panel.add_child(sep)

	_request_label = Label.new()
	_request_label.position = Vector2(20, 418)
	_request_label.size = Vector2(280, 80)
	_request_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	panel.add_child(_request_label)

	_bring_button = Button.new()
	_bring_button.position = Vector2(20, 640)
	_bring_button.size = Vector2(280, 50)
	_bring_button.text = "Открыть каталог"
	_bring_button.pressed.connect(_on_bring_pressed)
	panel.add_child(_bring_button)

	_next_button = Button.new()
	_next_button.position = Vector2(20, 640)
	_next_button.size = Vector2(280, 50)
	_next_button.text = "Следующий →"
	_next_button.visible = false
	_next_button.pressed.connect(_on_next_pressed)
	panel.add_child(_next_button)

	_set_content_visible(false)


func _set_content_visible(enabled: bool) -> void:
	_portrait.visible = enabled
	_name_label.visible = enabled
	_dialogue_label.visible = enabled
	_request_label.visible = enabled
	_bring_button.visible = enabled
	_next_button.visible = enabled


func show_customer(customer: Customer) -> void:
	_set_content_visible(true)
	_name_label.text = customer.name if customer.name != "" else "Покупатель"
	_dialogue_label.text = customer.dialogue_enter

	match customer.request_type:
		Customer.RequestType.KNOWS_TITLE:
			_request_label.text = "Ищет: «%s»" % customer.request_book
		Customer.RequestType.KNOWS_GENRE:
			_request_label.text = "Просит: %s" % Book.genre_to_string(customer.request_genre)
		Customer.RequestType.DOESNT_KNOW:
			_request_label.text = "Подсказки: %s" % ", ".join(customer.visual_hints)
		Customer.RequestType.WANTS_CONDITION:
			_request_label.text = "Нужна %s книга (%s)" % [
				Book.condition_to_string(customer.required_condition),
				Book.genre_to_string(customer.target_genre)
			]
		Customer.RequestType.KNOWS_SEQUEL:
			_request_label.text = "Читал «%s», хочет продолжение" % customer.request_book
		Customer.RequestType.KNOWS_MOOD:
			_request_label.text = "Настроение: %s" % ", ".join(customer.mood_hints)

	_bring_button.visible = true
	_next_button.visible = false


func show_result(customer: Customer, satisfied: bool) -> void:
	_dialogue_label.text = customer.dialogue_correct if satisfied else customer.dialogue_wrong
	_bring_button.visible = false
	_next_button.visible = true


func _on_bring_pressed() -> void:
	bring_book_requested.emit()


func _on_next_pressed() -> void:
	_set_content_visible(false)
	next_customer_requested.emit()
