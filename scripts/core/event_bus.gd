extends Node
## EventBus — centralized signal hub for all game systems.
## Add signals here as needed. Use typed parameters where possible.

# --- Player ---
signal player_moved(position: Vector3)
signal player_interacted(object_id: String)
signal camera_changed(mode: String)
signal player_inventory_changed()
signal player_money_changed(new_amount: float)

# --- World / Chunks ---
signal chunk_requested(chunk_id: String)
signal chunk_loaded(chunk_id: String)
signal chunk_unloaded(chunk_id: String)
signal world_object_changed(chunk_id: String, object_id: String)

# --- Supermarket ---
signal product_sold(product_id: String, quantity: int, revenue: float)
signal product_purchased(product_id: String, quantity: int, cost: float)
signal inventory_changed(store_id: String)
signal shelf_restocked(shelf_id: String)
signal shelf_empty(shelf_id: String)
signal product_expired(product_id: String, quantity: int)
signal customer_entered(customer_id: String)
signal customer_left(customer_id: String, spent: float)
signal checkout_completed(transaction_id: String, total: float)
signal price_changed(product_id: String, new_price: float)

# --- Employees ---
signal employee_hired(employee_id: String)
signal employee_fired(employee_id: String)
signal employee_task_assigned(employee_id: String, task: String)

# --- Business ---
signal business_level_changed(store_id: String, new_level: int)
signal delivery_arrived(supplier_id: String, order_id: String)
signal contract_signed(contract_id: String)
signal contract_expired(contract_id: String)

# --- Construction ---
signal object_placed(object_id: String, position: Vector3)
signal object_removed(object_id: String)
signal construction_mode_entered()
signal construction_mode_exited()

# --- RPG / Quests ---
signal quest_started(quest_id: String)
signal quest_objective_updated(quest_id: String, objective_id: String)
signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String)
signal skill_unlocked(skill_id: String)
signal reputation_changed(faction: String, new_value: float)
signal relationship_changed(npc_id: String, new_value: float)

# --- Save System ---
signal autosave_started()
signal autosave_completed(slot: String)
signal save_failed(reason: String)
signal save_completed(slot: String)
signal game_loaded(slot: String)

# --- World Events ---
signal world_event_started(event_id: String)
signal world_event_ended(event_id: String)
signal time_of_day_changed(hour: int)
signal day_changed(day: int)
signal season_changed(season: String)
signal weather_changed(weather_type: String)

# --- UI ---
signal notification_requested(message: String, type: String, duration: float)
signal hud_update_requested()
signal menu_opened(menu_id: String)
signal menu_closed(menu_id: String)

# --- Economy ---
signal market_price_updated(product_id: String, new_price: float)
signal tax_collected(amount: float)
signal expense_recorded(category: String, amount: float)
