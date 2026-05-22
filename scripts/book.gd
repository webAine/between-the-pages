class_name Book
extends Resource

enum Genre {
	FICTION,    # Художественная
	DETECTIVE,  # Детектив
	ADVENTURE,  # Приключения
	POETRY,     # Поэзия
	CHILDREN,   # Детская
	HISTORY,    # История
	SCIENCE,    # Наука
}

enum Thickness {
	THIN,    # ~100 стр
	MEDIUM,  # ~300 стр
	THICK,   # ~600+ стр
}


enum Condition {
	NEW,   # новая
	READ,  # читаная
	WORN,  # потёртая
}

enum Decoration {
	NONE,          # без украшений
	GOLD_ORNAMENT, # золотой орнамент
	EMBOSSED,      # тиснение
}

@export var title: String = ""
@export var author: String = ""
@export var genre: Genre = Genre.FICTION
@export var description: String = ""
@export var cover_color: Color = Color.WHITE
@export var thickness: Thickness = Thickness.MEDIUM
@export var cabinet_index: int = 0
@export var shelf_row: int = 1
@export var shelf_position: int = 1
@export var is_available: bool = true
@export var condition: Condition = Condition.READ
@export var decoration: Decoration = Decoration.NONE
@export var sequel_title: String = ""
@export var edition: String = ""


static func _parse_genre(s: String) -> Genre:
	match s:
		"FICTION":   return Genre.FICTION
		"DETECTIVE": return Genre.DETECTIVE
		"ADVENTURE": return Genre.ADVENTURE
		"POETRY":    return Genre.POETRY
		"CHILDREN":  return Genre.CHILDREN
		"HISTORY":   return Genre.HISTORY
		"SCIENCE":   return Genre.SCIENCE
	return Genre.FICTION


static func _parse_condition(s: String) -> Condition:
	match s:
		"NEW":  return Condition.NEW
		"READ": return Condition.READ
		"WORN": return Condition.WORN
	return Condition.READ


static func _parse_decoration(s: String) -> Decoration:
	match s:
		"NONE":          return Decoration.NONE
		"GOLD_ORNAMENT": return Decoration.GOLD_ORNAMENT
		"EMBOSSED":      return Decoration.EMBOSSED
	return Decoration.NONE


static func genre_to_string(g: Genre) -> String:
	match g:
		Genre.FICTION:   return "Художественная"
		Genre.DETECTIVE: return "Детектив"
		Genre.ADVENTURE: return "Приключения"
		Genre.POETRY:    return "Поэзия"
		Genre.CHILDREN:  return "Детская"
		Genre.HISTORY:   return "История"
		Genre.SCIENCE:   return "Наука"
	return "Неизвестно"


static func thickness_to_string(t: Thickness) -> String:
	match t:
		Thickness.THIN:   return "тонкая"
		Thickness.MEDIUM: return "средняя"
		Thickness.THICK:  return "толстая"
	return ""


static func condition_to_string(c: Condition) -> String:
	match c:
		Condition.NEW:  return "новая"
		Condition.READ: return "читаная"
		Condition.WORN: return "потёртая"
	return ""


static func decoration_to_string(d: Decoration) -> String:
	match d:
		Decoration.NONE:          return ""
		Decoration.GOLD_ORNAMENT: return "золотой орнамент"
		Decoration.EMBOSSED:      return "тиснение"
	return ""


static func ordinal_ru(n: int) -> String:
	match n:
		1: return "1-я"
		2: return "2-я"
		3: return "3-я"
		4: return "4-я"
		5: return "5-я"
		6: return "6-я"
		7: return "7-я"
		8: return "8-я"
		9: return "9-я"
		10: return "10-я"
	return "%d-я" % n
