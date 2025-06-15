extends Control

class_name DebugMenuEditor

signal value_updated(newValue: Variant, parameter: String, category: String)

@onready var mainPanel: PanelContainer = %MainPanel
@onready var MainPanelContainer: MarginContainer = %MainPanelContainer
@onready var buttonsContainer: GridContainer = %ButtonsContainer
@onready var showButton: Button = %ShowButton
@onready var outsideButton: Button = %OutsideButton

var menuList: Array[GridContainer]
var chevrons: Dictionary = {
	"up": load("res://Demo/Resources/DebugMenuUIElements/ChevronUp.svg"),
	"down": load("res://Demo/Resources/DebugMenuUIElements/ChevronDown.svg")
}

class ParameterContents:
	var parameter: String
	var type: DebugParameterContainer.ParameterTypes
	var defaultValue: Variant
	var extraData: Variant
	func _init(newParameter: String, newType: DebugParameterContainer.ParameterTypes, newDefaultValue: Variant, newExtraData: Variant = null):
		parameter = newParameter
		type = newType
		defaultValue = newDefaultValue
		extraData = newExtraData

class ParameterCategory:
	var category: String
	var contents: Array[ParameterContents]

func initialize(parameterCategoryList: Array[ParameterCategory], gridSize: int = 1) -> void:
	await ready
	var buttonTheme: Dictionary = get_control_theme(showButton)
	for i in range(len(parameterCategoryList)):
		var menu: GridContainer = GridContainer.new()
		menu.columns = gridSize
		var categoryButton: Button = Button.new()
		set_control_theme(categoryButton, buttonTheme)
		categoryButton.text = parameterCategoryList[i].category.capitalize()
		categoryButton.pressed.connect(show_menu.bind(i))
		categoryButton.custom_minimum_size.y = showButton.custom_minimum_size.y
		buttonsContainer.add_child(categoryButton)
		categoryButton.custom_minimum_size.x = categoryButton.size.x + 10
		for parameter in parameterCategoryList[i].contents:
			var parameterContainer: DebugParameterContainer = DebugParameterContainer.new(parameter.parameter, parameter.type, parameter.defaultValue, parameter.extraData)
			parameterContainer.value_updated.connect(value_updated.emit.bind(parameterCategoryList[i].category))
			menu.add_child(parameterContainer)
		menuList.append(menu)
		menu.visible = i == 0
		MainPanelContainer.add_child(menu)

func get_control_theme(node: Control) -> Dictionary:
	return {
		"color/font_color": node.get_theme_color("font_color"),
		"color/font_outline_color": node.get_theme_color("font_outline_color"),
		"constant/outline_size": node.get_theme_constant("outline_size"),
		"stylebox/normal": node.get_theme_stylebox("pressed"),
		"stylebox/pressed": node.get_theme_stylebox("pressed"),
		"stylebox/hover": node.get_theme_stylebox("hover")
	}

func set_control_theme(node: Control, styles: Dictionary) -> void:
	for style in styles:
		var themeName: PackedStringArray = style.split("/")
		match themeName[0]:
			"color":
				if node.has_theme_color(themeName[1]):
					node.add_theme_color_override(themeName[1], styles[style])
			"constant":
				if node.has_theme_constant(themeName[1]):
					node.add_theme_constant_override(themeName[1], styles[style])
			"stylebox":
				if node.has_theme_stylebox(themeName[1]):
					node.add_theme_stylebox_override(themeName[1], styles[style])

func _on_show(toggled: bool) -> void:
	if toggled:
		showButton.icon = chevrons.up
	else:
		showButton.icon = chevrons.down
	mainPanel.visible = toggled
	buttonsContainer.visible = toggled
	showButton.release_focus()

func show_menu(index: int) -> void:
	for i in range(len(menuList)):
		menuList[i].visible = i == index

func _on_outside():
	outsideButton.grab_focus()
	outsideButton.release_focus()
