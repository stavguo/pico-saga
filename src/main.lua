state, current_state = {}

function change_state(name, payload)
    if current_state and states[current_state].exit then
        states[current_state].exit()
    end
    current_state = name
    if states[current_state].enter then
        states[current_state].enter(payload)
    end
end

function _init()
    castles, units = {}, {}
    states = {
        setup = create_setup_state(),
        overworld = create_overworld_state(),
        castle = create_castle_state(),
        move_unit = create_move_state(),
        action_menu = create_action_menu_state(),
        attack_menu = create_attack_menu_state(),
        combat = create_combat_state(),
        enemy_turn = create_enemy_turn(),
        enemy_phase = create_enemy_phase(),
        phase_change = create_phase_change(),
        castle_capture = create_castle_capture_state(),
        turn_end = create_turn_end_confirmation(),
        game_over = create_game_over()
    }
    change_state("setup")
end

function _update60()
    if states[current_state].update then
        states[current_state].update()
    end
end

function _draw()
    cls()
    map()
    draw_side_bars()
    if states[current_state].draw then
        states[current_state].draw()
    end
end
