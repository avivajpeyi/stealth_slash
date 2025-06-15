extends VBoxContainer

class_name DebugParameterContainer

var parameterLabel: Label
var numericContent: SpinBox
var boolContent: CheckButton
var listContent: OptionButton

enum ParameterTypes {NUMERIC, BOOL, LIST}

signal value_updated(newValue: Variant, parameter: String)

class NumericData:
	var minValue: float
	var maxValue: float
	var step: float
	func _init(newMin: float, newMax: float, newStep: float = 0.1):
		minValue = newMin
		maxValue = newMax
		step = newStep

func _init(parameter: String, type: ParameterTypes, defaultValue: Variant, extraData: Variant = null) -> void:
	alignment = ALIGNMENT_CENTER
	if type != ParameterTypes.BOOL:
		parameterLabel = Label.new()
		parameterLabel.text = parameter
		add_child(parameterLabel)
	match type:
		ParameterTypes.NUMERIC:
			numericContent = SpinBox.new()
			numericContent.min_value = extraData.minValue
			numericContent.max_value = extraData.maxValue
			numericContent.step = extraData.step
			numericContent.value = defaultValue
			numericContent.value_changed.connect(value_updated.emit.bind(parameter))
			numericContent.allow_greater = true
			add_child(numericContent)
		ParameterTypes.BOOL:
			boolContent = CheckButton.new()
			boolContent.text = parameter
			boolContent.button_pressed = defaultValue
			boolContent.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			boolContent.toggled.connect(value_updated.emit.bind(parameter))
			add_child(boolContent)
		ParameterTypes.LIST:
			listContent = OptionButton.new()
			for i in range(len(extraData)):
				listContent.add_item(extraData[i], i)
			listContent.selected = defaultValue
			listContent.item_selected.connect(value_updated.emit.bind(parameter))
			add_child(listContent)
