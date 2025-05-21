extends Node

## Configuration
signal display_language_updated

## UI
signal harvest_forest(order: int)
signal progress_button_hover(resource_generator: ResourceGenerator)
signal progress_button_unhover(resource_generator: ResourceGenerator)
signal progress_button_pressed(resource_generator: ResourceGenerator, source: String)
signal progress_button_cooldown_end(resource_generator: ResourceGenerator)
signal substance_craft_button_pressed(substance_data: SubstanceData)
signal progress_button_disabled(id: String)
signal manager_button_hover(worker_role: WorkerRole, node: Node)
signal manager_button_unhover(worker_role: WorkerRole, node: Node)
signal manager_button_add(worker_role: WorkerRole)
signal manager_button_del(worker_role: WorkerRole)
signal manager_button_smart_add(worker_role: WorkerRole)
signal manager_button_smart_del(worker_role: WorkerRole)
signal npc_event_interacted(npc_id: String, npc_event_id: String, option: int)
signal enemy_hover(enemy_data: EnemyData)
signal tab_clicked(tab_data: TabData)
signal tab_changed(tab_data: TabData)
signal toggle_button_pressed(id: String, toggle_id: String)
signal toggle_scale_pressed(scale_: int)
signal toggle_manager_mode_pressed(mode: int)
signal toggle_darkness_mode_pressed(mode: int)
signal resource_ui_updated(
	resource_tracker_item: ResourceTrackerItem, amount: int, change: int, source_id: String
)
signal info_hover(title: String, into: String)
signal info_hover_shader(title: String, into: String)
signal info_hover_tab(tab_data: TabData)
signal resource_storage_hover(resource: ResourceGenerator)
signal resource_storage_unhover(resource: ResourceGenerator)
signal deaths_door_open(enemy_data: EnemyData)
signal deaths_door(enemy_data: EnemyData, option: int)
signal audio_settings_update(toggle: bool, value: float, id: String)
signal effect_settings_update(toggle: bool, value: float, id: String)
signal display_mode_settings_toggle
signal display_resolution_settings_toggle
signal heart_click
signal heart_unclick
signal prestige_cancel
signal prestige_yes
signal prestige_reborn
signal open_import_modal
signal open_export_modal(save_file_name: String)

## CONTROLLER
signal main_ready
signal progress_button_paid(resource_generator: ResourceGenerator, source: String)
signal progress_button_unpaid(resource_generator: ResourceGenerator, source: String)
signal substance_craft_button_paid(substance_data: SubstanceData)
signal substance_craft_button_unpaid(substance_data: SubstanceData)
signal resource_generated(id: String, amount: int, source_id: String)
signal substance_generated(id: String, source_id: String)
signal substance_multiple_generated(id: String, amount: int, source_id: String)
signal worker_generated(id: String, amount: int, source_id: String)
signal worker_allocated(id: String, amount: int, source_id: String)
signal event_triggered(event_data: EventData, vals: Array)
signal npc_event_triggered(npc_event: NpcEvent)
signal npc_event_update(npc_id: String, npc_event_id: String, option: int)
signal progress_button_unlock(resource_generator: ResourceGenerator)
signal manager_button_unlock(worker_role: WorkerRole)
signal tab_unlock(tab_data: TabData)
signal tab_level_up(tab_data: TabData)
signal worker_efficiency_set(efficiencies: Dictionary, generate: bool)
signal enemy_damage(damage: int, source_id: String)
signal set_ui_theme(theme: Resource)
signal toggle_button(id: String, toggle_id: String)
signal toggle_scale(scale_: int)
signal toggle_manager_mode(mode: int)
signal toggle_darkness_mode(mode: int)
signal deaths_door_decided(enemy_data: EnemyData, option: int)
signal save_entered(seconds_delta: int, seconds_delta_expected: int)
signal autosave(seconds_delta: int, seconds_delta_expected: int)
signal offline_progress_processed(
	seconds_delta: int, worker_progress: Dictionary, enemy_progress: Dictionary, factor: float
)
signal audio_settings_updated(toggle: bool, value: float, id: String)
signal effect_settings_updated(toggle: bool, value: float, id: String)
signal display_mode_settings_updated(display_mode: String)
signal display_resolution_settings_updated(width: int, height: int)
signal prestige_condition_fail
signal prestige_condition_disabled
signal prestige_condition_pass(infinity_count: int)
signal soul
signal clear_npc_event

## MANAGER
signal resource_updated(id: String, total: int, amount: int, source_id: String)
signal substance_updated(id: String, total_amount: int, source_id: String)
signal worker_updated(id: String, total: int, amount: int)
signal event_saved(event_data: EventData, vals: Array, index: int)
signal npc_event_saved(npc_event: NpcEvent)
signal npc_event_updated(npc_id: String, npc_event_id: String, option: int)
signal progress_button_unlocked(resource_generator: ResourceGenerator)
signal manager_button_unlocked(worker_role: WorkerRole)
signal tab_unlocked(tab_data: TabData)
signal tab_leveled_up(tab_data: TabData)
signal worker_efficiency_updated(efficiencies: Dictionary, generate: bool)
signal enemy_damaged(total_damage: int, damage: int, source_id: String)
signal deaths_door_resolved(enemy_data: EnemyData, new_enemy_data: EnemyData, option: int)

# BuH Scene
signal player_damaged
signal player_death
signal boss_start
signal boss_click
signal boss_cycle
signal boss_end
signal game_end(ending: int)


func _ready() -> void:
	if Game.PARAMS["debug_logs"]:
		print("_AUTOLOAD _READY: " + self.get_name())
