class_name BookInspectionUI
extends CanvasLayer

signal book_confirmed(book: Book)
signal book_returned

var _book: Book = null
var _cover_rect: ColorRect
var _title_label: Label
var _author_label: Label
var _details_label: Label
var _condition_label: Label
var _decoration_label: Label
var _give_btn: Button


func _ready() -> void:
	layer = 1
	_build_ui()
	visible = false


func show_book(book: Book, can_give: bool) -> void:
	_book = book
	_cover_rect.color = book.cover_color

	if book.condition == Book.Condition.WORN:
		_title_label.text = "название неразборчиво"
		_author_label.text = ""
	else:
		_title_label.text = book.title
		_author_label.text = book.author

	_details_label.text = "%s · %s" % [Book.genre_to_string(book.genre), Book.thickness_to_string(book.thickness)]
	_condition_label.text = "Состояние: %s" % Book.condition_to_string(book.condition)

	var dec: String = Book.decoration_to_string(book.decoration)
	_decoration_label.text = dec if dec != "" else ""
	_decoration_label.visible = dec != ""

	_give_btn.disabled = not can_give
	visible = true


func _build_ui() -> void:
	var panel := ColorRect.new()
	panel.color = Color(0.14, 0.10, 0.08, 1.0)
	panel.position = Vector2(280, 200)
	panel.size = Vector2(400, 300)
	add_child(panel)

	_cover_rect = ColorRect.new()
	_cover_rect.position = Vector2(20, 20)
	_cover_rect.size = Vector2(55, 80)
	panel.add_child(_cover_rect)

	_title_label = Label.new()
	_title_label.position = Vector2(90, 20)
	_title_label.size = Vector2(290, 40)
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	panel.add_child(_title_label)

	_author_label = Label.new()
	_author_label.position = Vector2(90, 64)
	_author_label.size = Vector2(290, 24)
	panel.add_child(_author_label)

	_details_label = Label.new()
	_details_label.position = Vector2(90, 90)
	_details_label.size = Vector2(290, 24)
	panel.add_child(_details_label)

	_condition_label = Label.new()
	_condition_label.position = Vector2(20, 112)
	_condition_label.size = Vector2(360, 24)
	panel.add_child(_condition_label)

	_decoration_label = Label.new()
	_decoration_label.position = Vector2(20, 136)
	_decoration_label.size = Vector2(360, 24)
	panel.add_child(_decoration_label)

	var sep := ColorRect.new()
	sep.color = Color(0.3, 0.25, 0.2)
	sep.position = Vector2(20, 170)
	sep.size = Vector2(360, 1)
	panel.add_child(sep)

	_give_btn = Button.new()
	_give_btn.text = "Отдать покупателю"
	_give_btn.position = Vector2(20, 242)
	_give_btn.size = Vector2(170, 42)
	_give_btn.pressed.connect(_on_give_pressed)
	panel.add_child(_give_btn)

	var return_btn := Button.new()
	return_btn.text = "Положить обратно"
	return_btn.position = Vector2(210, 242)
	return_btn.size = Vector2(170, 42)
	return_btn.pressed.connect(_on_return_pressed)
	panel.add_child(return_btn)


func _on_give_pressed() -> void:
	visible = false
	book_confirmed.emit(_book)


func _on_return_pressed() -> void:
	visible = false
	book_returned.emit()
