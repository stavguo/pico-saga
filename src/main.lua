function _init()
    -- Initialize FSM
    fsm:change_state("setup")
end

function _update()
    fsm:update()
end

function _draw()
    cls()
    map()
    fsm:draw()
end
