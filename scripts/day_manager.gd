class_name DayManager
extends Node

signal customer_arrived(customer: Customer)
signal customer_left(customer: Customer, satisfied: bool, money_delta: int)
signal day_ended(day: int)

const MAX_CUSTOMERS_PER_DAY := 5
const BOOK_PRICE_BY_THICKNESS := {
	Book.Thickness.THIN:   8,
	Book.Thickness.MEDIUM: 12,
	Book.Thickness.THICK:  18,
}

var day_number: int = 1
var all_customers: Array[Customer] = []
var catalog: Catalog = null

var _queue: Array[Customer] = []
var _current_index: int = -1
var _current_customer: Customer = null
var _last_visit_day: Dictionary = {}
var _failed_visits: Dictionary = {}   # customer_id -> int
var _comeback_day: Dictionary = {}    # customer_id -> int (-1 = ждёт книгу)
var _visit_progress: Dictionary = {}  # customer_id -> {visit_idx: int, attempt_idx: int}
var _rng := RandomNumberGenerator.new()


func setup(customers: Array[Customer], p_catalog: Catalog) -> void:
	all_customers = customers
	catalog = p_catalog
	_rng.randomize()


func start_day() -> void:
	_queue = _build_queue()
	_current_index = -1
	_current_customer = null


func next_customer() -> void:
	_current_index += 1
	if _current_index >= _queue.size():
		day_ended.emit(day_number)
		day_number += 1
		return
	var raw_customer := _queue[_current_index]
	var customer := _prepare_for_visit(raw_customer)
	_current_customer = customer
	if customer.id != "":
		_last_visit_day[customer.id] = day_number
	customer_arrived.emit(customer)


func resolve_visit(book: Book) -> void:
	if _current_customer == null:
		return
	var satisfied := _check_book(book, _current_customer)
	var money_delta := 0
	if satisfied:
		money_delta = BOOK_PRICE_BY_THICKNESS.get(book.thickness, 12)
		if _current_customer.id != "":
			_failed_visits[_current_customer.id] = 0
			_comeback_day.erase(_current_customer.id)
			_on_visit_success(_current_customer.id)
	else:
		_track_failed_visit(_current_customer)
	customer_left.emit(_current_customer, satisfied, money_delta)
	_current_customer = null


func notify_book_available(title: String) -> void:
	for customer in all_customers:
		if customer.id == "":
			continue
		if _comeback_day.get(customer.id, 0) != -1:
			continue
		var progress := _get_progress(customer.id)
		var visit_idx: int = progress["visit_idx"]
		var target_book: String = ""
		if not customer.visits.is_empty() and visit_idx < customer.visits.size():
			target_book = (customer.visits[visit_idx] as Customer.Visit).book
		else:
			target_book = customer.request_book
		if target_book.to_lower() == title.to_lower():
			_comeback_day[customer.id] = day_number + _rng.randi_range(2, 5)
			_failed_visits[customer.id] = 0


func _get_progress(customer_id: String) -> Dictionary:
	if not _visit_progress.has(customer_id):
		_visit_progress[customer_id] = {"visit_idx": 0, "attempt_idx": 0}
	return _visit_progress[customer_id]


func _prepare_for_visit(customer: Customer) -> Customer:
	if customer.visits.is_empty():
		return customer
	var progress := _get_progress(customer.id)
	var visit_idx: int = progress["visit_idx"]
	if visit_idx >= customer.visits.size():
		return customer
	var visit := customer.visits[visit_idx] as Customer.Visit
	var attempt_idx: int = mini(progress["attempt_idx"], visit.attempts.size() - 1)
	if visit.attempts.is_empty():
		return customer
	var attempt := visit.attempts[attempt_idx] as Customer.Attempt
	var copy := customer.duplicate()
	copy.request_book = visit.book
	copy.dialogue_enter = attempt.enter
	copy.dialogue_wait = attempt.wait
	copy.dialogue_correct = attempt.correct
	copy.dialogue_wrong = attempt.wrong
	return copy


func _on_visit_success(customer_id: String) -> void:
	var progress := _get_progress(customer_id)
	progress["visit_idx"] += 1
	progress["attempt_idx"] = 0
	_visit_progress[customer_id] = progress


func _track_failed_visit(customer: Customer) -> void:
	if customer.id == "":
		return
	var fails: int = _failed_visits.get(customer.id, 0) + 1
	_failed_visits[customer.id] = fails
	var progress := _get_progress(customer.id)
	var visit_idx: int = progress["visit_idx"]
	if not customer.visits.is_empty() and visit_idx < customer.visits.size():
		var visit := customer.visits[visit_idx] as Customer.Visit
		var next_attempt: int = progress["attempt_idx"] + 1
		if next_attempt < visit.attempts.size():
			progress["attempt_idx"] = next_attempt
			_visit_progress[customer.id] = progress
	if fails >= 3:
		_comeback_day[customer.id] = -1


func get_current_customer() -> Customer:
	return _current_customer


func _build_queue() -> Array[Customer]:
	var queue: Array[Customer] = []

	for customer in all_customers:
		if customer.tier == Customer.Tier.REGULAR and _is_regular_due(customer):
			queue.append(customer)

	var random_pool: Array[Customer] = []
	for customer in all_customers:
		if customer.tier == Customer.Tier.RANDOM:
			random_pool.append(customer)
	random_pool.shuffle()

	for customer in random_pool:
		if queue.size() >= MAX_CUSTOMERS_PER_DAY:
			break
		var c := _prepare_random_customer(customer)
		queue.append(c)

	queue.shuffle()
	return queue


func _prepare_random_customer(template: Customer) -> Customer:
	if template.request_type == Customer.RequestType.KNOWS_TITLE:
		if catalog == null or template.request_book != "":
			return template
		var available: Array[Book] = []
		for book in catalog.books:
			if book.is_available:
				available.append(book)
		if available.is_empty():
			return template
		var copy := template.duplicate()
		copy.request_book = available[_rng.randi() % available.size()].title
		return copy

	if template.request_type == Customer.RequestType.KNOWS_SEQUEL:
		if catalog == null or template.request_book != "":
			return template
		var sequels: Array[Book] = []
		for book in catalog.books:
			if book.is_available and book.sequel_title != "":
				sequels.append(book)
		if sequels.is_empty():
			return template
		var copy := template.duplicate()
		copy.request_book = sequels[_rng.randi() % sequels.size()].sequel_title
		return copy

	return template


func _check_book(book: Book, customer: Customer) -> bool:
	match customer.request_type:
		Customer.RequestType.KNOWS_TITLE:
			return book.title.to_lower() == customer.request_book.to_lower()
		Customer.RequestType.KNOWS_GENRE:
			return book.genre == customer.request_genre
		Customer.RequestType.DOESNT_KNOW:
			return book.genre == customer.target_genre
		Customer.RequestType.WANTS_CONDITION:
			return book.condition == customer.required_condition and book.genre == customer.target_genre
		Customer.RequestType.KNOWS_SEQUEL:
			return book.sequel_title.to_lower() == customer.request_book.to_lower()
		Customer.RequestType.KNOWS_MOOD:
			return book.genre == customer.target_genre
	return false


func _is_regular_due(customer: Customer) -> bool:
	if not customer.visits.is_empty():
		var progress := _get_progress(customer.id)
		if progress["visit_idx"] >= customer.visits.size():
			return false
	var comeback: int = _comeback_day.get(customer.id, 0)
	if comeback == -1:
		return false
	if comeback > 0:
		if day_number >= comeback:
			_comeback_day.erase(customer.id)
			return true
		return false
	var last: int = _last_visit_day.get(customer.id, -1)
	if last == -1:
		return day_number >= customer.first_visit_day
	match customer.visit_frequency:
		Customer.VisitFrequency.WEEKLY:
			return (day_number - last) >= 7
		Customer.VisitFrequency.BIWEEKLY:
			return (day_number - last) >= 14
		Customer.VisitFrequency.RANDOM:
			return _rng.randf() < 0.25
	return false
