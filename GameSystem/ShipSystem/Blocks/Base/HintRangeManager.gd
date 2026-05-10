extends Node2D
class_name HintRangeManager

## 範圍提示管理器：負責集中渲染所有方塊的提示範圍，避免 alpha 重疊過深
## 分類：武器類為紅色，推進器為藍色
## 渲染分三次：1. 半透明填充 2. 凸包邊框 3. 個別形狀邊框

# 分類顏色設定 (容易擴充)
var category_colors = {
	"weapon": {
		"fill": Color(1.0, 0.576, 0.518, 0.071),
		"border": Color(1.0, 0.478, 0.41, 0.6),
		"detail": Color(1, 0.4, 0.4, 0.3)
	},
	"thruster": {
		"fill": Color(0.457, 0.631, 1.0, 0.25),
		"border": Color(0.226, 0.451, 1.0, 0.6),
		"detail": Color(0.528, 0.568, 1.0, 0.3)
	}
}

# 儲存註冊的節點，而不是頂點資料
var _indicators: Array[RangeIndicator] = []

func _ready() -> void:
	DI.register("_hint_range_manager", self)

func _process(_delta: float) -> void:
	# 每幀重繪即可，資料由 Indicator 節點即時提供
	queue_redraw()

func register_indicator(indicator: RangeIndicator) -> void:
	if not _indicators.has(indicator):
		_indicators.append(indicator)

func unregister_indicator(indicator: RangeIndicator) -> void:
	_indicators.erase(indicator)

func _draw() -> void:
	if not DebugSetting.force_show_range_indicators and not BuildMenu.is_menu_open:
		return
		
	# 收集所有有效 Indicator 的資料
	var data_by_category = {}
	
	for indicator in _indicators:
		if not is_instance_valid(indicator):
			continue
			
		var data = indicator.get_global_points()
		if data.is_empty():
			continue
			
		var category = data["category"]
		if not category in data_by_category:
			data_by_category[category] = []
			
		data_by_category[category].append({
			"points": data["fill"],
			"border": data["border"]
		})
		
	# 開始分類繪製
	for category in data_by_category.keys():
		var shapes = data_by_category[category]
		var colors = category_colors.get(category, {
			"fill": Color(1, 1, 1, 0.05),
			"border": Color(1, 1, 1, 0.4),
			"detail": Color(1, 1, 1, 0.15)
		})
		
		var polys = []
		for shape in shapes:
			if shape["points"].size() >= 3:
				polys.append(shape["points"])
			
		if polys.is_empty():
			continue
			
		# 簡單地將多邊形與已有的合併 (Godot 4 僅支援兩兩合併)
		var merged_polys = []
		for poly in polys:
			if merged_polys.is_empty():
				merged_polys.append(poly)
			else:
				var merged = false
				for k in range(merged_polys.size()):
					var result = Geometry2D.merge_polygons(merged_polys[k], poly)
					if result.size() == 1:
						merged_polys[k] = result[0]
						merged = true
						break
				if not merged:
					merged_polys.append(poly)
				
		# 渲染分三次
		
		# 1. 繪製半透明多邊形 (合併後的填充)
		for poly in merged_polys:
			draw_colored_polygon(poly, colors["fill"])
		
		# 2. 繪製合併後的邊框實線
		for poly in merged_polys:
			var closed_poly = poly.duplicate()
			closed_poly.append(poly[0]) # 閉合
			draw_polyline(closed_poly, colors["border"], 2.0)
		
		# 3. 繪製各個形狀的個別邊框 (細節)
		for shape in shapes:
			var border = shape["border"]
			if border.size() >= 2:
				draw_polyline(border, colors["detail"], 1.0)
