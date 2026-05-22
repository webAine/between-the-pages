class_name Customer
extends Resource

enum Tier {
	STORY,
	REGULAR,
	RANDOM,
}

enum RequestType {
	KNOWS_TITLE,
	KNOWS_GENRE,
	DOESNT_KNOW,
	WANTS_CONDITION,
	KNOWS_SEQUEL,
	KNOWS_MOOD,
}

enum VisitFrequency {
	WEEKLY,
	BIWEEKLY,
	RANDOM,
}

class Attempt:
	var enter: String = ""
	var wait: String = ""
	var correct: String = ""
	var wrong: String = ""

class Visit:
	var book: String = ""
	var attempts: Array = []  # Array of Attempt

@export var id: String = ""
@export var name: String = ""
@export var tier: Tier = Tier.REGULAR
@export var appearance: String = ""

@export var request_type: RequestType = RequestType.KNOWS_TITLE
@export var request_book: String = ""
@export var request_genre: Book.Genre = Book.Genre.FICTION
@export var target_genre: Book.Genre = Book.Genre.FICTION
@export var required_condition: Book.Condition = Book.Condition.NEW
@export var visual_hints: Array[String] = []
@export var mood_hints: Array[String] = []

@export var dialogue_enter: String = ""
@export var dialogue_wait: String = ""
@export var dialogue_correct: String = ""
@export var dialogue_wrong: String = ""

@export var diary_index: int = 0
@export var visit_frequency: VisitFrequency = VisitFrequency.WEEKLY
@export var first_visit_day: int = 1

var visits: Array = []  # Array of Visit


static func load_all_from_file(path: String) -> Array[Customer]:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Customer: не удалось открыть файл " + path)
		return []

	var json_text := file.get_as_text()
	file.close()

	var data = JSON.parse_string(json_text)
	if data == null:
		push_error("Customer: ошибка парсинга JSON в " + path)
		return []

	var result: Array[Customer] = []
	for entry in data:
		result.append(_from_dict(entry))
	return result


static func _from_dict(d: Dictionary) -> Customer:
	var c := Customer.new()
	c.id = d.get("id", "")
	c.name = d.get("name", "")
	c.tier = _parse_tier(d.get("tier", "REGULAR"))
	c.appearance = d.get("appearance", "")
	c.request_type = _parse_request_type(d.get("request_type", "KNOWS_TITLE"))
	c.request_book = d.get("request_book", "")
	c.request_genre = Book._parse_genre(d.get("request_genre", "FICTION"))
	c.target_genre = Book._parse_genre(d.get("target_genre", "FICTION"))
	c.required_condition = Book._parse_condition(d.get("required_condition", "NEW"))
	c.visual_hints = Array(d.get("visual_hints", []), TYPE_STRING, "", null)
	c.mood_hints = Array(d.get("mood_hints", []), TYPE_STRING, "", null)
	c.dialogue_enter = d.get("dialogue_enter", "")
	c.dialogue_wait = d.get("dialogue_wait", "")
	c.dialogue_correct = d.get("dialogue_correct", "")
	c.dialogue_wrong = d.get("dialogue_wrong", "")
	c.diary_index = d.get("diary_index", 0)
	c.visit_frequency = _parse_frequency(d.get("visit_frequency", "WEEKLY"))
	c.first_visit_day = d.get("first_visit_day", 1)
	var visits_data = d.get("visits", [])
	if visits_data.size() > 0:
		c.visits = _parse_visits(visits_data)
	return c


static func _parse_visits(data: Array) -> Array:
	var result: Array = []
	for v_data in data:
		var visit := Visit.new()
		visit.book = v_data.get("book", "")
		for a_data in v_data.get("attempts", []):
			var attempt := Attempt.new()
			attempt.enter = a_data.get("enter", "")
			attempt.wait = a_data.get("wait", "")
			attempt.correct = a_data.get("correct", "")
			attempt.wrong = a_data.get("wrong", "")
			visit.attempts.append(attempt)
		result.append(visit)
	return result


static func _parse_tier(s: String) -> Tier:
	match s:
		"STORY":   return Tier.STORY
		"REGULAR": return Tier.REGULAR
		"RANDOM":  return Tier.RANDOM
	return Tier.REGULAR


static func _parse_request_type(s: String) -> RequestType:
	match s:
		"KNOWS_TITLE":    return RequestType.KNOWS_TITLE
		"KNOWS_GENRE":    return RequestType.KNOWS_GENRE
		"DOESNT_KNOW":    return RequestType.DOESNT_KNOW
		"WANTS_CONDITION": return RequestType.WANTS_CONDITION
		"KNOWS_SEQUEL":   return RequestType.KNOWS_SEQUEL
		"KNOWS_MOOD":     return RequestType.KNOWS_MOOD
	return RequestType.KNOWS_TITLE


static func _parse_frequency(s: String) -> VisitFrequency:
	match s:
		"WEEKLY":   return VisitFrequency.WEEKLY
		"BIWEEKLY": return VisitFrequency.BIWEEKLY
		"RANDOM":   return VisitFrequency.RANDOM
	return VisitFrequency.WEEKLY
