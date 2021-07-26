#=
 JuliaTris - A Tetris clone in Julia/Qt
  Copyright (C) 2021 J. Férard <https://github.com/jferard>

 This file is part of JuliaTris.

 JuliaTris is free software: you can redistribute it and/or modify it under the
 terms of the GNU General Public License as published by the Free Software
 Foundation, either version 3 of the License, or (at your option) any later
 version.

 JuliaTris is distributed in the hope that it will be useful, but WITHOUT ANY
 WARRANTY; without even the implied warranty of MERCHANTABILITY or
 FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
 for more details.

 You should have received a copy of the GNU General Public License along with
 this program. If not, see <http://www.gnu.org/licenses/>.
=#
ENV["QSG_RENDER_LOOP"] = "basic"

using QML
using Qt5QuickControls2_jll
using JSON

include("Colors.jl")
include("Tetrominos.jl")
include("CurrentTetrominos.jl")
include("Board.jl")
include("BoardStates.jl")

using .Colors
using .Tetrominos
import .Tetrominos: fixed_color, get_tetromino_map, get_random_tetromino_map
using .CurrentTetrominos
import .CurrentTetrominos: is_tetromino_there
using .Board
import .Board: position_allowed, merge_tetromino!, mark_lines!, remove_lines!, get_color,
                get_tetro_i, get_tetro_j, get_height
using .BoardStates
import .BoardStates: next_tetromino!, move!, get_board_map, get_random_board_map

# from https://doc.qt.io/qt-5/qt.html#Key-enum
const KEY_ESCAPE = 0x01000000
const KEY_LEFT = 0x01000012
const KEY_UP = 0x01000013
const KEY_RIGHT = 0x01000014
const KEY_DOWN = 0x01000015
const KEY_SPACE = 0x20
const KEY_B = 0x42
const KEY_N = 0x4e

const qmlfile = joinpath(dirname(Base.source_path()), "qml", "tetris.qml")

const SIDE = 20

BoardCell = Union{Empty, Wall, Tetromino, Marked}

mutable struct Events
    lines_completed::Int
    target_height_reached::Bool
    ground_touched::Bool

    function Events()
        return new(0, false, false)
    end
end

function reset!(events::Events)
   events.lines_completed = 0
   events.target_height_reached = false
   events.ground_touched = false
end

mutable struct GameState
    events::Events
    started::Bool
    paused::Bool
    lost::Bool
    won::Bool
end

new_game_state() = GameState(Events(), false, true, false, false)

abstract type Game end

mutable struct GameUnlimited <: Game
    model::GameModel
    board_state::BoardState
    state::GameState
end

mutable struct Game25 <: Game
    model::GameModel
    board_state::BoardState
    state::GameState
end

mutable struct GameGround <: Game
    model::GameModel
    board_state::BoardState
    state::GameState
end

mutable struct GameCleaner <: Game
    model::GameModel
    board_state::BoardState
    state::GameState
end

game_unlimited(base_level::Int32, base_height::Int32)::Game = GameUnlimited(convert(Int64, base_level), convert(Int64, base_height), 0)

game_25(base_level::Int32, base_height::Int32)::Game = Game25(convert(Int64, base_level), convert(Int64, base_height), 25)

game_ground(base_level::Int32, base_height::Int32)::Game = GameGround(convert(Int64, base_level), convert(Int64, base_height), 0)

game_cleaner(base_level::Int32, base_height::Int32)::Game = GameCleaner(convert(Int64, base_level), convert(Int64, base_height), 0)


function GameUnlimited(base_level::Int64, base_height::Int64, base_lines_count::Int64)::Game
    model = GameModel(base_level, base_height, base_lines_count, -1)
    board_state = new_board_state(model)
    state = new_game_state()
    return GameUnlimited(model, board_state, state)
end

function Game25(base_level::Int64, base_height::Int64, base_lines_count::Int64)::Game
    model = GameModel(base_level, base_height, base_lines_count, -1)
    board_state = new_board_state(model)
    state = new_game_state()
    return Game25(model, board_state, state)
end

function GameGround(base_level::Int64, base_height::Int64, base_lines_count::Int64)::Game
    model = GameModel(base_level, base_height, base_lines_count, -1)
    board_state = new_board_state(model)
    state = new_game_state()
    return GameGround(model, board_state, state)
end

function GameCleaner(base_level::Int64, base_height::Int64, base_lines_count::Int64)::Game
    model = GameModel(base_level, base_height, base_lines_count, 2)
    board_state = new_board_state(model)
    state = new_game_state()
    return GameCleaner(model, board_state, state)
end

function reset!(game::Game)
    game.board_state = new_board_state(game.model)
    game.state = new_game_state()
    game.state.started = true
    game.state.paused = false
end

####################################################
function update_game_map!(game::Game)
    global gameMap
    gameMap["level"] = game.board_state.cur_level
    gameMap["lines"] = game.board_state.lines_count
    gameMap["score"] = game.board_state.score
    gameMap["gameStarted"] = Int(game.state.started)
    gameMap["gamePaused"] = Int(game.state.paused)
    gameMap["gameLost"] = Int(game.state.lost)
    gameMap["gameWon"] = Int(game.state.won)
end

function update_best_map!(board_state::BoardState)
    global best_map
    if board_state.lines_count > best_map["linesCount"]
        best_map["linesCount"] = board_state.lines_count
    end
    if board_state.score > best_map["score"]
        best_map["score"] = board_state.score
    end
end
################################################################

SCORES = [40, 100, 300, 1000]

function remove_lines!(game::Game)
    game.state.events.lines_completed = remove_lines!(game.board_state.board)
end

function fall!(game::Game)
    board_state = game.board_state
    cur_tetromino = board_state.cur_tetromino
    if !move!(board_state, 1, 0, 0)
        merge_tetromino!(board_state.board, board_state.cur_tetromino)
        if mark_lines!(board_state.board)
            board_state.marked = true
        end
        check_height!(game)
        check_ground!(game)
        next_tetromino!(board_state)
        update_game_board!(game)
    end
end

function check_height!(game::Game)
    if get_height(game.board_state.board) <= game.model.target_height
        game.state.events.target_height_reached = true
    end
end    

function check_ground!(game::Game)
    if ground_touched(game.board_state.board, game.board_state.cur_tetromino)
        game.state.events.ground_touched = true
    end
end

function ground_touched(board::GameBoard, cur_tetromino::CurrentTetromino)::Bool
    arr = cur_tetromino.tetromino.arrays[cur_tetromino.orientation]
    tetro_i = cur_tetromino.i
    for k in 1:TETROMINO_ROW_COUNT
        for l in 1:TETROMINO_COL_COUNT
            if arr[k, l] == 1
                cell_i = tetro_i + k - 1 # caveat here
                if cell_i == board.row_count - 1
                    return true
                end
            end
        end
    end
    return false
end

function key_press(key::Int32)
    global game
    if game == nothing
        return
    end
    state = game.state
    board_state = game.board_state

    if key == KEY_SPACE
        if !state.started
            state.started = true
            state.paused = false
        elseif state.won || state.lost
            reset!(game)
        else
            state.paused = !state.paused
        end
        update_game_board!(game)
        update_game_map!(game)
    end

    if !state.started || state.paused
        return
    end

    cur_tetromino = board_state.cur_tetromino
    if key == KEY_LEFT
        move!(board_state, 0, -1, 0)
    elseif key == KEY_RIGHT
        move!(board_state, 0, 1, 0)
    elseif key == KEY_B
        move!(board_state, 0, 0, 1)
    elseif key == KEY_N
        move!(board_state, 0, 0, -1)
    elseif key == KEY_DOWN
        move!(board_state, 1, 0, 0)
    end
end

function game_loop()
    global game
    handle_events(game)

    state = game.state
    board_state = game.board_state
    if state.paused
        update_game_board!(game)
        return
    end

    board_state.round += 1
    if board_state.round >= board_state.speed
        if board_state.marked
            remove_lines!(game)
            board_state.marked = false
            check_height!(game)
        else
            fall!(game)
        end
        board_state.round = 0
    end
    update_game_map!(game)
    update_game_board!(game)
end

function handle_events(game::GameUnlimited)
    state = game.state
    events = game.state.events

    if events.lines_completed > 0
        board_state = game.board_state
        board_state.lines_count += events.lines_completed
        board_state.score += SCORES[events.lines_completed]
        if board_state.lines_count % 10 == 0
             lines_level = floor(Int64, board_state.lines_count // 10)
             if board_state.cur_level < lines_level && lines_level <= MAX_LEVEL
                board_state.speed -= SPEED_UP
                board_state.cur_level += 1
             end
        end
        update_game_map!(game)
        update_best_map!(board_state)
    end
    reset!(events)
end

function handle_events(game::Game25)
    state = game.state
    events = state.events

    if events.lines_completed > 0
        board_state = game.board_state
        board_state.lines_count -= events.lines_completed
        board_state.score += SCORES[events.lines_completed]
        if board_state.lines_count <= 0
            board_state.lines_count == 0
            state.won = true
            state.paused = true
        end
        update_game_map!(game)
        update_best_map!(board_state)
    end
    reset!(events)
end

function handle_events(game::GameGround)
    state = game.state
    events = state.events
    board_state = game.board_state

    if events.lines_completed > 0
        board_state.lines_count += events.lines_completed
        board_state.score += SCORES[events.lines_completed]
        update_game_map!(game)
        update_best_map!(board_state)
    end
    if events.ground_touched
        state.won = true
        state.paused = true
        update_game_map!(game)
    end
    reset!(events)
end

function handle_events(game::GameCleaner)
    state = game.state
    events = state.events

    if events.lines_completed > 0
        board_state = game.board_state
        board_state.lines_count -= events.lines_completed
        board_state.score += SCORES[events.lines_completed]
        update_game_map!(game)
        update_best_map!(board_state)
    end
    if events.target_height_reached
        state.won = true
        state.paused = true
        update_game_map!(game)
    end
    reset!(events)
end

################
# Update board #
################
function update_game_board!(game::Game)
    if game.state.paused
        gameMap["board"] = get_random_board_map(game.board_state)
        gameMap["next"] = get_random_tetromino_map()
    else
        gameMap["board"] = get_board_map(game.board_state)
        gameMap["next"] = get_tetromino_map(game.board_state.next_tetromino)
    end
end

########
# INIT #
########

game = nothing
gameMap = QML.JuliaPropertyMap("score" => "0", "lines" => 0, "level" => 0,
                               "gameLost" => 0, "gameStarted" => 0, "gamePaused" => 0,
                               "gameWon" => 0, "board" => [], "next" => []
                               )

function init_game(game_type, level::Int32, height::Int32)
    global game
    if game_type == "unlimited"
        game = game_unlimited(level, height)
    elseif game_type == "25"
        game = game_25(level, height)
    elseif game_type == "ground"
        game = game_ground(level, height)
    elseif game_type == "cleaner"
        game = game_cleaner(level, height)
    elseif game_type == "classic"
        game = game_unlimited(level, 0)
    else
        return
    end
    update_game_map!(game)
end

@qmlfunction init_game
@qmlfunction game_loop
@qmlfunction key_press

best_map = QML.JuliaPropertyMap("linesCount" => 0, "score" => 0)
try
    open("juliatris.json", "r") do source
        global best_map
        best = JSON.parse(source)
        best_map = QML.JuliaPropertyMap(best)
    end
catch e
    println(e)
end

loadqml(qmlfile, game=gameMap, TILE_SIZE=20, best=best_map)
exec()

open("juliatris.json", "w") do dest
    JSON.print(dest, best_map)
end
