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

# 儲存註冊的資料
# 格式: { "category": [ { "points": PackedVector2Array, "border": PackedVector2Array }, ... ] }
var _registered_data = {}

func _ready() -> void:
	DI.register("_hint_range_manager", self)

func _process(_delta: float) -> void:
	# 每幀清空，等待節點重新註冊，以自動處理移動與刪除
	_registered_data.clear()
	# 觸發重新繪製
	queue_redraw()

func register_range(category: String, fill_points_global: PackedVector2Array, border_points_global: PackedVector2Array) -> void:
	if not category in _registered_data:
		_registered_data[category] = []
	_registered_data[category].append({
		"points": fill_points_global,
		"border": border_points_global
	})

func _draw() -> void:
	if not DebugSetting.force_show_range_indicators and not BuildMenu.is_menu_open:
		return
		
	for category in _registered_data.keys():
		var shapes = _registered_data[category]
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
