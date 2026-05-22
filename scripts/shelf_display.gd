class_name ShelfDisplay
extends CanvasLayer

signal book_clicked(book: Book)

const CABINET_WIDTH := 200
const BOOK_HEIGHT := 95
const SHELF_Y := [55, 175, 295]
const BOOK_WIDTHS := {
	Book.Thickness.THIN: 16,
	Book.Thickness.MEDIUM: 26,
	Book.Thickness.THICK: 40,
}

var _catalog: Catalog = null
var _scroll: ScrollContainer
var _cabinet_names: Array[String] = []
var _actual_positions: Dictionary = {} # Book -> Vector2i(cabinet, row)
var _sort_keys: Dictionary = {} # Book -> float (порядок внутри ряда)

var _drag_book: Book = null
var _drag_rect: ColorRect = null
var _drag_ghost: ColorRect = null
var _drop_highlight: ColorRect = null
var _slot_preview: ColorRect = null
var _press_position: Vector2 = Vector2.ZERO
var _is_pressing: bool = false
var _dragging: bool = false

var _row_rects: Dictionary = {}
var _highlighted_row: Vector2i = Vector2i(-1, -1)


func _ready() -> void:
	layer = 1
	for i in 9:
		_cabinet_names.append("Шкаф %d" % (i + 1))
	_build_frame()
	_build_drag_visuals()


func _process(_delta: float) -> void:
	if not _is_pressing:
		return

	var mouse_pos := get_viewport().get_mouse_position()

	if not _dragging:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_is_pressing = false
			book_clicked.emit(_drag_book)
			return
		if (mouse_pos - _press_position).length() > 8.0:
			_start_drag(mouse_pos)
		return

	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_complete_drop(mouse_pos)
		return

	var bw: int = BOOK_WIDTHS.get(_drag_book.thickness, 26)
	_drag_ghost.position = mouse_pos - Vector2(bw / 2.0, BOOK_HEIGHT / 2.0)
	_update_drop_highlight(mouse_pos)


func get_actual_position(book_title: String) -> Vector2i:
	return _actual_positions.get(book_title, Vector2i(-1, -1))


func setup(catalog: Catalog) -> void:
	_catalog = catalog
	_randomize_all()
	_populate()


func refresh() -> void:
	for child in _scroll.get_children():
		child.queue_free()
	_populate()


func _randomize_all() -> void:
	_actual_positions.clear()
	_sort_keys.clear()
	if _catalog == null:
		return
	var idx := 0
	for book in _catalog.books:
		if not book.is_available:
			idx += 1
			continue
		_actual_positions[book.title] = Vector2i(randi() % 9, randi() % 3)
		_sort_keys[book.title] = float(idx)
		idx += 1


func _build_drag_visuals() -> void:
	_drop_highlight = ColorRect.new()
	_drop_highlight.color = Color(1.0, 1.0, 0.8, 0.2)
	_drop_highlight.size = Vector2(CABINET_WIDTH, BOOK_HEIGHT)
	_drop_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drop_highlight.visible = false
	add_child(_drop_highlight)

	_drag_ghost = ColorRect.new()
	_drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_ghost.modulate.a = 0.75
	_drag_ghost.visible = false
	add_child(_drag_ghost)

	_slot_preview = ColorRect.new()
	_slot_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slot_preview.modulate.a = 0.5
	_slot_preview.visible = false
	add_child(_slot_preview)


func _start_drag(mouse_pos: Vector2) -> void:
	_dragging = true
	if _drag_rect != null:
		_drag_rect.visible = false
	_apply_gap_close()
	var bw: int = BOOK_WIDTHS.get(_drag_book.thickness, 26)
	_drag_ghost.color = _drag_book.cover_color
	_drag_ghost.size = Vector2(bw, BOOK_HEIGHT)
	_drag_ghost.position = mouse_pos - Vector2(bw / 2.0, BOOK_HEIGHT / 2.0)
	_drag_ghost.visible = true
	_slot_preview.color = _drag_book.cover_color
	_slot_preview.size = Vector2(bw, BOOK_HEIGHT)


func _apply_gap_close() -> void:
	var drag_pos: Vector2i = _actual_positions.get(_drag_book.title, Vector2i(_drag_book.cabinet_index, _drag_book.shelf_row - 1))
	var bx := 8
	for entry in (_row_rects.get(drag_pos, []) as Array):
		var rect := entry["rect"] as ColorRect
		if rect == _drag_rect:
			continue
		rect.position.x = float(bx)
		bx += BOOK_WIDTHS.get((entry["book"] as Book).thickness, 26) + 2


func _complete_drop(mouse_pos: Vector2) -> void:
	_dragging = false
	_is_pressing = false
	_drag_ghost.visible = false
	_drop_highlight.visible = false
	_slot_preview.visible = false
	_highlighted_row = Vector2i(-1, -1)

	var target := _get_cabinet_row_at(mouse_pos)
	if target.x >= 0:
		_actual_positions[_drag_book.title] = target
		var content_x := mouse_pos.x + _scroll.scroll_horizontal
		var x_in_cabinet := content_x - float(target.x * (CABINET_WIDTH + 15))
		_sort_keys[_drag_book.title] = _get_sort_key_for_drop(target.x, target.y, x_in_cabinet)

	for child in _scroll.get_children():
		child.queue_free()
	call_deferred("_populate")
	_drag_rect = null
	_drag_book = null


func _get_sort_key_for_drop(target_cabinet: int, target_row: int, x_in_cabinet: float) -> float:
	var row_books: Array[Book] = []
	for book in _catalog.books:
		if not book.is_available:
			continue
		var pos: Vector2i = _actual_positions.get(book.title, Vector2i(book.cabinet_index, book.shelf_row - 1))
		if pos.x == target_cabinet and pos.y == target_row and book != _drag_book:
			row_books.append(book)

	row_books.sort_custom(func(a: Book, b: Book) -> bool:
		return _sort_keys.get(a.title, 0.0) < _sort_keys.get(b.title, 0.0)
	)

	if row_books.is_empty():
		return 0.0

	var bx := 8
	var centers: Array[float] = []
	var keys: Array[float] = []
	for book in row_books:
		var bw: int = BOOK_WIDTHS.get(book.thickness, 26)
		centers.append(float(bx) + float(bw) / 2.0)
		keys.append(_sort_keys.get(book.title, 0.0))
		bx += bw + 2

	if x_in_cabinet <= centers[0]:
		return keys[0] - 1.0

	for i in range(centers.size() - 1):
		if x_in_cabinet <= centers[i + 1]:
			return (keys[i] + keys[i + 1]) / 2.0

	return keys[-1] + 1.0


func _get_cabinet_row_at(mouse_pos: Vector2) -> Vector2i:
	var content_x := mouse_pos.x + _scroll.scroll_horizontal
	var content_y := mouse_pos.y - _scroll.position.y

	var cabinet := int(content_x / (CABINET_WIDTH + 15))
	if cabinet < 0 or cabinet >= 9:
		return Vector2i(-1, -1)

	var cab_start_x := cabinet * (CABINET_WIDTH + 15)
	if content_x < cab_start_x or content_x > cab_start_x + CABINET_WIDTH:
		return Vector2i(-1, -1)

	for row in range(3):
		if content_y >= SHELF_Y[row] and content_y <= SHELF_Y[row] + BOOK_HEIGHT:
			return Vector2i(cabinet, row)

	return Vector2i(-1, -1)


func _get_insertion_x(target_cabinet: int, target_row: int, x_in_cabinet: float) -> float:
	var row_books: Array[Book] = []
	for book in _catalog.books:
		if not book.is_available:
			continue
		var pos: Vector2i = _actual_positions.get(book.title, Vector2i(book.cabinet_index, book.shelf_row - 1))
		if pos.x == target_cabinet and pos.y == target_row and book != _drag_book:
			row_books.append(book)

	row_books.sort_custom(func(a: Book, b: Book) -> bool:
		return _sort_keys.get(a.title, 0.0) < _sort_keys.get(b.title, 0.0)
	)

	if row_books.is_empty():
		return 8.0

	var bx := 8
	var left_edges: Array[float] = []
	var right_edges: Array[float] = []
	for book in row_books:
		var bw: int = BOOK_WIDTHS.get(book.thickness, 26)
		left_edges.append(float(bx))
		right_edges.append(float(bx + bw))
		bx += bw + 2

	var centers: Array[float] = []
	for i in range(left_edges.size()):
		centers.append((left_edges[i] + right_edges[i]) / 2.0)

	if x_in_cabinet <= centers[0]:
		return left_edges[0]

	for i in range(centers.size() - 1):
		if x_in_cabinet <= centers[i + 1]:
			return right_edges[i] + 1.0

	return right_edges[-1] + 1.0


func _restore_row(row_key: Vector2i) -> void:
	if row_key.x < 0:
		return
	if _drag_book != null:
		var drag_pos: Vector2i = _actual_positions.get(_drag_book.title, Vector2i(_drag_book.cabinet_index, _drag_book.shelf_row - 1))
		if row_key == drag_pos:
			_apply_gap_close()
			return
	for entry in (_row_rects.get(row_key, []) as Array):
		(entry["rect"] as ColorRect).position.x = entry["original_x"]


func _update_row_preview(target: Vector2i, x_in_cabinet: float) -> void:
	var bw: int = BOOK_WIDTHS.get(_drag_book.thickness, 26)
	var insert_x := _get_insertion_x(target.x, target.y, x_in_cabinet)
	var cab_screen_x := target.x * (CABINET_WIDTH + 15) - _scroll.scroll_horizontal
	_slot_preview.position = Vector2(cab_screen_x + insert_x, _scroll.position.y + SHELF_Y[target.y])
	_slot_preview.visible = true
	var bx := 8
	for entry in (_row_rects.get(target, []) as Array):
		var rect := entry["rect"] as ColorRect
		if rect == _drag_rect:
			continue
		var base_x := float(bx)
		rect.position.x = base_x + (bw + 2 if base_x >= insert_x else 0)
		bx += BOOK_WIDTHS.get((entry["book"] as Book).thickness, 26) + 2


func _update_drop_highlight(mouse_pos: Vector2) -> void:
	var target := _get_cabinet_row_at(mouse_pos)
	if target != _highlighted_row:
		_restore_row(_highlighted_row)
		_highlighted_row = target
	if target.x >= 0:
		var cab_screen_x := target.x * (CABINET_WIDTH + 15) - _scroll.scroll_horizontal
		_drop_highlight.position = Vector2(cab_screen_x, _scroll.position.y + SHELF_Y[target.y])
		_drop_highlight.visible = true
		var content_x := mouse_pos.x + _scroll.scroll_horizontal
		var x_in_cabinet := content_x - float(target.x * (CABINET_WIDTH + 15))
		_update_row_preview(target, x_in_cabinet)
	else:
		_drop_highlight.visible = false
		_slot_preview.visible = false


func _build_frame() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.03, 0.02)
	bg.position = Vector2(0, 0)
	bg.size = Vector2(960, 720)
	add_child(bg)

	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(0, 10)
	_scroll.size = Vector2(960, 705)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)


func _populate() -> void:
	if _catalog == null:
		return
	_row_rects.clear()
	_highlighted_row = Vector2i(-1, -1)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.add_child(hbox)

	for i in range(9):
		_build_cabinet(hbox, i)


func _build_cabinet(parent: Control, index: int) -> void:
	var cabinet := ColorRect.new()
	cabinet.color = Color(0.18, 0.12, 0.08)
	cabinet.custom_minimum_size = Vector2(CABINET_WIDTH, 420)
	cabinet.clip_contents = true
	parent.add_child(cabinet)

	var ci := index
	var header := LineEdit.new()
	header.text = _cabinet_names[index]
	header.editable = false
	header.position = Vector2(5, 5)
	header.size = Vector2(CABINET_WIDTH - 10, 24)
	cabinet.add_child(header)

	header.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if not header.editable:
				header.editable = true
				header.grab_focus()
				header.select_all()
	)
	header.focus_exited.connect(func() -> void:
		_cabinet_names[ci] = header.text
		header.editable = false
	)
	header.text_submitted.connect(func(_t: String) -> void:
		_cabinet_names[ci] = header.text
		header.editable = false
		header.release_focus()
	)

	for row_i in range(3):
		_build_shelf_row(cabinet, index, row_i, SHELF_Y[row_i])


func _build_shelf_row(cabinet: ColorRect, cabinet_index: int, row: int, y: int) -> void:
	var plank := ColorRect.new()
	plank.color = Color(0.30, 0.20, 0.12)
	plank.position = Vector2(5, y + BOOK_HEIGHT)
	plank.size = Vector2(CABINET_WIDTH - 10, 8)
	cabinet.add_child(plank)

	var row_books: Array[Book] = []
	for book in _catalog.books:
		if not book.is_available:
			continue
		var pos: Vector2i = _actual_positions.get(book.title, Vector2i(book.cabinet_index, book.shelf_row - 1))
		if pos.x == cabinet_index and pos.y == row:
			row_books.append(book)

	row_books.sort_custom(func(a: Book, b: Book) -> bool:
		return _sort_keys.get(a.title, 0.0) < _sort_keys.get(b.title, 0.0)
	)

	var bx := 8
	for book in row_books:
		var bw: int = BOOK_WIDTHS.get(book.thickness, 26)
		if bx + bw > CABINET_WIDTH - 8:
			break

		var rect := ColorRect.new()
		rect.color = book.cover_color
		rect.position = Vector2(bx, y)
		rect.size = Vector2(bw, BOOK_HEIGHT)
		rect.mouse_filter = Control.MOUSE_FILTER_STOP
		cabinet.add_child(rect)

		var row_key := Vector2i(cabinet_index, row)
		if not _row_rects.has(row_key):
			_row_rects[row_key] = []
		(_row_rects[row_key] as Array).append({"rect": rect, "book": book, "original_x": float(bx)})

		var catalog_pos := Vector2i(book.cabinet_index, book.shelf_row - 1)
		var actual_pos: Vector2i = _actual_positions.get(book.title, catalog_pos)
		if actual_pos != catalog_pos:
			var indicator := ColorRect.new()
			indicator.color = Color(1.0, 0.55, 0.0, 0.9)
			indicator.position = Vector2(0, 0)
			indicator.size = Vector2(8, 8)
			indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rect.add_child(indicator)

		var b: Book = book
		var r: ColorRect = rect
		rect.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				_is_pressing = true
				_dragging = false
				_drag_book = b
				_drag_rect = r
				_press_position = get_viewport().get_mouse_position()
		)

		bx += bw + 2
