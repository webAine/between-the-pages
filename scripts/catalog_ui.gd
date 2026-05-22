class_name CatalogUI
extends CanvasLayer

signal location_updated(book: Book)

var _catalog: Catalog = null
var _shelf_display: ShelfDisplay = null
var _current_book: Book = null

var _panel: ColorRect
var _book_list_container: VBoxContainer
var _card_panel: ColorRect
var _card_color_rect: ColorRect
var _card_title: Label
var _card_author: Label
var _card_genre: Label
var _card_description: Label
var _card_condition: Label
var _loc_cabinet: OptionButton
var _loc_shelf: OptionButton
var _loc_position: SpinBox


func _ready() -> void:
	layer = 3
	_build_ui()
	visible = false


func setup(catalog: Catalog, shelf_display: ShelfDisplay) -> void:
	_catalog = catalog
	_shelf_display = shelf_display


func open() -> void:
	visible = true
	_show_genre(Book.Genre.DETECTIVE)


func close() -> void:
	visible = false
	_card_panel.visible = false


func _build_ui() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.65)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	_panel = ColorRect.new()
	_panel.color = Color(0.12, 0.09, 0.07, 1.0)
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.size = Vector2(900, 520)
	_panel.offset_left = -450
	_panel.offset_right = 450
	_panel.offset_top = -260
	_panel.offset_bottom = 260
	add_child(_panel)

	var header := Label.new()
	header.text = "Каталог"
	header.position = Vector2(20, 10)
	header.size = Vector2(200, 30)
	_panel.add_child(header)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.position = Vector2(858, 8)
	close_btn.size = Vector2(34, 34)
	close_btn.pressed.connect(close)
	_panel.add_child(close_btn)

	_build_genre_column()
	_build_book_list()
	_build_card()


func _build_genre_column() -> void:
	var genres := [
		Book.Genre.DETECTIVE,
		Book.Genre.FICTION,
		Book.Genre.ADVENTURE,
		Book.Genre.HISTORY,
		Book.Genre.SCIENCE,
		Book.Genre.POETRY,
		Book.Genre.CHILDREN,
	]

	var col := VBoxContainer.new()
	col.position = Vector2(10, 50)
	col.size = Vector2(170, 460)
	_panel.add_child(col)

	for genre in genres:
		var btn := Button.new()
		btn.text = Book.genre_to_string(genre)
		btn.custom_minimum_size = Vector2(170, 38)
		var g: Book.Genre = genre
		btn.pressed.connect(func(): _show_genre(g))
		col.add_child(btn)

	var div := ColorRect.new()
	div.color = Color(0.3, 0.25, 0.2)
	div.position = Vector2(188, 50)
	div.size = Vector2(2, 460)
	_panel.add_child(div)


func _build_book_list() -> void:
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(200, 50)
	scroll.size = Vector2(340, 460)
	_panel.add_child(scroll)

	_book_list_container = VBoxContainer.new()
	_book_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_book_list_container)

	var div := ColorRect.new()
	div.color = Color(0.3, 0.25, 0.2)
	div.position = Vector2(548, 50)
	div.size = Vector2(2, 460)
	_panel.add_child(div)


func _build_card() -> void:
	_card_panel = ColorRect.new()
	_card_panel.color = Color(0.16, 0.12, 0.09, 1.0)
	_card_panel.position = Vector2(560, 50)
	_card_panel.size = Vector2(330, 460)
	_card_panel.visible = false
	_panel.add_child(_card_panel)

	_card_color_rect = ColorRect.new()
	_card_color_rect.position = Vector2(10, 10)
	_card_color_rect.size = Vector2(26, 46)
	_card_panel.add_child(_card_color_rect)

	_card_title = Label.new()
	_card_title.position = Vector2(46, 10)
	_card_title.size = Vector2(274, 46)
	_card_title.autowrap_mode = TextServer.AUTOWRAP_WORD
	_card_panel.add_child(_card_title)

	_card_author = Label.new()
	_card_author.position = Vector2(10, 65)
	_card_author.size = Vector2(310, 24)
	_card_panel.add_child(_card_author)

	_card_genre = Label.new()
	_card_genre.position = Vector2(10, 90)
	_card_genre.size = Vector2(310, 24)
	_card_panel.add_child(_card_genre)

	_card_condition = Label.new()
	_card_condition.position = Vector2(10, 115)
	_card_condition.size = Vector2(310, 24)
	_card_panel.add_child(_card_condition)

	var sep := ColorRect.new()
	sep.color = Color(0.3, 0.25, 0.2)
	sep.position = Vector2(10, 145)
	sep.size = Vector2(310, 1)
	_card_panel.add_child(sep)

	_card_description = Label.new()
	_card_description.position = Vector2(10, 155)
	_card_description.size = Vector2(310, 170)
	_card_description.autowrap_mode = TextServer.AUTOWRAP_WORD
	_card_panel.add_child(_card_description)

	var loc_header := Label.new()
	loc_header.text = "Расположение в каталоге:"
	loc_header.position = Vector2(10, 332)
	loc_header.size = Vector2(310, 20)
	_card_panel.add_child(loc_header)

	var cab_label := Label.new()
	cab_label.text = "Шкаф"
	cab_label.position = Vector2(10, 358)
	cab_label.size = Vector2(40, 24)
	_card_panel.add_child(cab_label)

	_loc_cabinet = OptionButton.new()
	_loc_cabinet.position = Vector2(52, 355)
	_loc_cabinet.size = Vector2(60, 28)
	for i in range(1, 10):
		_loc_cabinet.add_item(str(i))
	_card_panel.add_child(_loc_cabinet)

	var shelf_label := Label.new()
	shelf_label.text = "Полка"
	shelf_label.position = Vector2(120, 358)
	shelf_label.size = Vector2(44, 24)
	_card_panel.add_child(shelf_label)

	_loc_shelf = OptionButton.new()
	_loc_shelf.position = Vector2(166, 355)
	_loc_shelf.size = Vector2(50, 28)
	for i in range(1, 4):
		_loc_shelf.add_item(str(i))
	_card_panel.add_child(_loc_shelf)

	var pos_label := Label.new()
	pos_label.text = "№"
	pos_label.position = Vector2(224, 358)
	pos_label.size = Vector2(20, 24)
	_card_panel.add_child(pos_label)

	_loc_position = SpinBox.new()
	_loc_position.position = Vector2(246, 355)
	_loc_position.size = Vector2(74, 28)
	_loc_position.min_value = 1
	_loc_position.max_value = 30
	_card_panel.add_child(_loc_position)

	var save_btn := Button.new()
	save_btn.text = "Сохранить запись"
	save_btn.position = Vector2(10, 418)
	save_btn.size = Vector2(310, 34)
	save_btn.pressed.connect(_on_save_location)
	_card_panel.add_child(save_btn)


func _is_misplaced(book: Book) -> bool:
	if _shelf_display == null:
		return false
	var actual := _shelf_display.get_actual_position(book.title)
	if actual.x < 0:
		return false
	return actual.x != book.cabinet_index or actual.y != book.shelf_row - 1


func _show_genre(genre: Book.Genre) -> void:
	_card_panel.visible = false

	for child in _book_list_container.get_children():
		child.queue_free()

	if _catalog == null:
		return

	var books := _catalog.find_by_genre(genre)
	for book in books:
		var btn := Button.new()
		btn.text = ("! " if _is_misplaced(book) else "") + book.title
		btn.custom_minimum_size = Vector2(310, 36)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		var b: Book = book
		btn.pressed.connect(func(): _show_card(b))
		_book_list_container.add_child(btn)


func _show_card(book: Book) -> void:
	_current_book = book
	_card_color_rect.color = book.cover_color
	_card_title.text = book.title
	_card_author.text = book.author
	_card_genre.text = "%s · %s" % [Book.genre_to_string(book.genre), Book.thickness_to_string(book.thickness)]
	var dec: String = Book.decoration_to_string(book.decoration)
	_card_condition.text = "Состояние: %s%s" % [Book.condition_to_string(book.condition), "  · " + dec if dec != "" else ""]
	_card_description.text = book.description
	_loc_cabinet.selected = book.cabinet_index
	_loc_shelf.selected = book.shelf_row - 1
	_loc_position.value = book.shelf_position
	_card_panel.visible = true


func _on_save_location() -> void:
	if _current_book == null:
		return
	_current_book.cabinet_index = _loc_cabinet.selected
	_current_book.shelf_row = _loc_shelf.selected + 1
	_current_book.shelf_position = int(_loc_position.value)
	location_updated.emit(_current_book)
	_show_genre(_current_book.genre)
	_show_card(_current_book)
