class_name Catalog
extends Resource

@export var books: Array[Book] = []


func find_by_title(search: String) -> Book:
	for book in books:
		if book.title.to_lower() == search.to_lower():
			return book
	return null


func find_by_genre(genre: Book.Genre) -> Array[Book]:
	var result: Array[Book] = []
	for book in books:
		if book.genre == genre and book.is_available:
			result.append(book)
	return result


static func load_from_file(path: String) -> Catalog:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Catalog: не удалось открыть файл " + path)
		return null

	var json_text := file.get_as_text()
	file.close()

	var data = JSON.parse_string(json_text)
	if data == null:
		push_error("Catalog: ошибка парсинга JSON в " + path)
		return null

	var catalog := Catalog.new()
	for entry in data:
		catalog.books.append(_book_from_dict(entry))
	return catalog


static func _book_from_dict(d: Dictionary) -> Book:
	var book := Book.new()
	book.title = d.get("title", "")
	book.author = d.get("author", "")
	book.genre = Book._parse_genre(d.get("genre", "FICTION"))
	book.description = d.get("description", "")
	var c: Array = d.get("cover_color", [1.0, 1.0, 1.0])
	book.cover_color = Color(c[0], c[1], c[2])
	book.thickness = _parse_thickness(d.get("thickness", "MEDIUM"))
	book.cabinet_index = d.get("cabinet_index", 0)
	book.shelf_row = int(d.get("shelf_row", 1))
	book.shelf_position = int(d.get("shelf_position", 1))
	book.is_available = d.get("is_available", true)
	book.condition = Book._parse_condition(d.get("condition", "READ"))
	book.decoration = Book._parse_decoration(d.get("decoration", "NONE"))
	book.sequel_title = d.get("sequel_title", "")
	book.edition = d.get("edition", "")
	return book


static func _parse_thickness(s: String) -> Book.Thickness:
	match s:
		"THIN":   return Book.Thickness.THIN
		"MEDIUM": return Book.Thickness.MEDIUM
		"THICK":  return Book.Thickness.THICK
	return Book.Thickness.MEDIUM


