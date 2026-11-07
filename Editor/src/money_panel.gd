extends Panel

signal money_changed(new_value: float, old_value: float)
@onready var btn_money: Button = %BtnMoney
@onready var lbl_money: Label = %LblMoney

var _money: float = 0.0
var money: float:
	set(value):
		var old_money = _money
		_money = value
		emit_signal("money_changed", _money, old_money)
	get:
		return _money

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(lbl_money)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	money += 1 * delta
	print(money)


func _on_btn_money_pressed() -> void:
	money += 1


func _on_money_changed(new_value: float, _old_value: float) -> void:
	lbl_money.text = str("$", new_value)
