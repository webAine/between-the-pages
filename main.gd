extends Node2D

var money: int = 500
var reputation: int = 30
var shelf_order: int = 10

var catalog: Catalog = null
var day_manager: DayManager = null
var _dialogue: CustomerDialogue = null
var _catalog_ui: CatalogUI = null
var _shelf_display: ShelfDisplay = null
var _day_results: DayResultsUI = null
var _inspection_ui: BookInspectionUI = null

var _day_money_earned: int = 0
var _day_satisfied: int = 0
var _day_total: int = 0
var _day_reputation_delta: int = 0

@onready var money_label: Label = $UI/HUD/MoneyLabel
@onready var reputation_label: Label = $UI/HUD/ReputationLabel
@onready var order_label: Label = $UI/HUD/OrderLabel


func _ready() -> void:
	catalog = Catalog.load_from_file("res://data/books.json")
	var customers := Customer.load_all_from_file("res://data/customers.json")

	day_manager = DayManager.new()
	day_manager.setup(customers, catalog)
	add_child(day_manager)

	_dialogue = CustomerDialogue.new()
	add_child(_dialogue)

	_shelf_display = ShelfDisplay.new()
	add_child(_shelf_display)
	_shelf_display.setup(catalog)
	_shelf_display.book_clicked.connect(_on_book_clicked)

	_inspection_ui = BookInspectionUI.new()
	add_child(_inspection_ui)
	_inspection_ui.book_confirmed.connect(_on_book_confirmed)

	_catalog_ui = CatalogUI.new()
	_catalog_ui.setup(catalog, _shelf_display)
	add_child(_catalog_ui)
	_catalog_ui.location_updated.connect(_on_location_updated)

	_day_results = DayResultsUI.new()
	add_child(_day_results)
	_day_results.next_day_pressed.connect(_on_next_day)

	day_manager.customer_arrived.connect(_on_customer_arrived)
	day_manager.customer_left.connect(_on_customer_left)
	day_manager.day_ended.connect(_on_day_ended)

	_dialogue.bring_book_requested.connect(_on_bring_book)
	_dialogue.next_customer_requested.connect(_on_next_customer)

	update_hud()
	day_manager.start_day()
	day_manager.next_customer()



func _on_customer_arrived(customer: Customer) -> void:
	_dialogue.show_customer(customer)


func _on_customer_left(customer: Customer, satisfied: bool, money_delta: int) -> void:
	_day_total += 1
	if satisfied:
		_day_satisfied += 1
		_day_money_earned += money_delta
		_day_reputation_delta += 5
		change_money(money_delta)
		change_reputation(5)
	else:
		_day_reputation_delta -= 3
		change_reputation(-3)
	_dialogue.show_result(customer, satisfied)


func _on_day_ended(day: int) -> void:
	_day_results.show_results(day, _day_satisfied, _day_total, _day_money_earned, _day_reputation_delta)


func _on_next_day() -> void:
	_day_money_earned = 0
	_day_satisfied = 0
	_day_total = 0
	_day_reputation_delta = 0
	day_manager.start_day()
	_shelf_display.refresh()
	day_manager.next_customer()


func _on_bring_book() -> void:
	_catalog_ui.open()


func _on_book_clicked(book: Book) -> void:
	var can_give := day_manager.get_current_customer() != null
	_inspection_ui.show_book(book, can_give)


func _on_book_confirmed(book: Book) -> void:
	day_manager.resolve_visit(book)


func _on_next_customer() -> void:
	day_manager.next_customer()


func _on_location_updated(_book: Book) -> void:
	change_order(3)
	_shelf_display.refresh()


func update_hud() -> void:
	money_label.text = "Деньги: %d" % money
	reputation_label.text = "Репутация: %d" % reputation
	order_label.text = "Порядок: %d" % shelf_order


func change_money(amount: int) -> void:
	money += amount
	update_hud()


func change_reputation(amount: int) -> void:
	reputation = clampi(reputation + amount, 0, 100)
	update_hud()


func change_order(amount: int) -> void:
	shelf_order = clampi(shelf_order + amount, 0, 100)
	update_hud()
