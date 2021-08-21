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
import .BoardStates: move!, get_board_map, get_random_board_map, MAX_LEVEL

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

const REDRAW_BOARD = 1
const REDRAW_NEXT = 2

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
    restart::Bool
end

new_game_state() = GameState(Events(), false, true, false, false, false)

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

function game_unlimited(base_level::Int32, base_height::Int32, best::Any)::Game
    global best_map
    model = GameModel(base_level, base_height, 0, -1)
    board_state = new_board_state(model)
    state = new_game_state()
    best_map["linesCount"] = best["linesCount"][1]
    best_map["score"] = best["score"][1]
    return GameUnlimited(model, board_state, state)
end

function game_25(base_level::Int32, base_height::Int32, best::Any)::Game
    model = GameModel(base_level, base_height, 25, -1)
    board_state = new_board_state(model)
    state = new_game_state()
    best_map["score"] = best["score"][1]
    return Game25(model, board_state, state)
end

function game_ground(base_level::Int32, base_height::Int32, best::Any)::Game
    model = GameModel(base_level, base_height, 0, -1)
    board_state = new_board_state(model)
    state = new_game_state()
    best_map["score"] = best["score"][1]
    return GameGround(model, board_state, state)
end

function game_cleaner(base_level::Int32, base_height::Int32, best::Any)::Game
    model = GameModel(base_level, base_height, 0, 1)
    board_state = new_board_state(model)
    state = new_game_state()
    best_map["score"] = best["score"][1]
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
    global game_map
    game_map["level"] = game.board_state.cur_level
    game_map["lines"] = game.board_state.lines_count
    game_map["score"] = game.board_state.score
    game_map["gameStarted"] = Int(game.state.started)
    game_map["gamePaused"] = Int(game.state.paused)
    game_map["gameLost"] = Int(game.state.lost)
    game_map["gameWon"] = Int(game.state.won)
    game_map["gameRestart"] = Int(game.state.restart)
end

function update_best_map!(game::Game)
    global best_map
    board_state = game.board_state
    if board_state.lines_count > best_map["linesCount"]
        best_map["linesCount"] = board_state.lines_count
    end
    if board_state.score > best_map["score"]
        best_map["score"] = board_state.score
    end
end

function update_best_map!(game::GameUnlimited)
    global best_map
    board_state = game.board_state
    if board_state.lines_count > best_map["linesCount"]
        best_map["linesCount"] = board_state.lines_count
    end
    if board_state.score > best_map["score"]
        best_map["score"] = board_state.score
    end
end

function update_best_map!(game::Game25)
    global best_map
    board_state = game.board_state
    if board_state.score > best_map["score"]
        best_map["score"] = board_state.score
    end
end

function update_best_map!(game::GameGround)
    global best_map
    board_state = game.board_state
    if board_state.score > best_map["score"]
        best_map["score"] = board_state.score
    end
end

function update_best_map!(game::GameCleaner)
    global best_map
    board_state = game.board_state
    if board_state.score > best_map["score"]
        best_map["score"] = board_state.score
    end
end

"""
Update the best scores as JSON object.
"""
update_best!(game::Game) = ()

function update_best!(game::GameUnlimited)
    global best
    cur_best = best["unlimited"]
    board_state = game.board_state

    curLineCount = board_state.lines_count
    bestLinesCounts = cur_best["linesCount"]
    if curLineCount > bestLinesCounts[end-1]
        cur_best["linesCount"] = sort(vcat(bestLinesCounts, [curLineCount]), rev=true)[1:end-1]
    end

    curScore = board_state.score
    bestScores = cur_best["score"]
    if curScore > bestScores[end-1]
        cur_best["score"] = sort(vcat(bestScores, [curScore]), rev=true)[1:end-1]
    end
end

update_best!(game::Game25) = update_best!(game, "25")

update_best!(game::GameGround) = update_best!(game, "ground")

update_best!(game::GameCleaner) = update_best!(game, "cleaner")

function update_best!(game::Game, name::String)
    global best
    cur_best = best[name]
    board_state = game.board_state

    curScore = board_state.score
    bestScores = cur_best["score"]
    if curScore > bestScores[end-1]
        cur_best["score"] = sort(vcat(bestScores, [curScore]), rev=true)[1:end-1]
    end
end

################################################################

SCORES = [40, 100, 300, 1000]

function remove_lines!(game::Game)
    game.state.events.lines_completed = remove_lines!(game.board_state.board)
    game_map["signal"] = REDRAW_BOARD | REDRAW_NEXT
end

function fall!(game::Game)
    board_state = game.board_state
    cur_tetromino = board_state.cur_tetromino
    game_map["signal"] = REDRAW_BOARD
    if !move!(board_state, 1, 0, 0)
        merge_tetromino!(board_state.board, board_state.cur_tetromino)
        if mark_lines!(board_state.board)
            board_state.marked = true
        end
        check_height!(game)
        check_ground!(game)
        next_tetromino!(game)
        update_game_board!(game)
        game_map["signal"] |= REDRAW_NEXT
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

function next_tetromino!(game::Game)
    board_state = game.board_state
    tetromino = board_state.next_tetromino
    tetro_i = get_tetro_i(board_state.board)
    tetro_j = get_tetro_j(board_state.board)
    if position_allowed(board_state.board, tetromino, tetro_i, tetro_j, 1)
        board_state.cur_tetromino = CurrentTetromino(tetro_i, tetro_j, tetromino, 1)
        board_state.next_tetromino = random_tetromino()
    else
        game.state.lost = true
        game.state.paused = true
        update_best!(game)
        update_game_map!(game)
    end
end


function key_press(key::Int32)
    global game
    if game == nothing
        return
    end
    state = game.state
    board_state = game.board_state

    if key == KEY_ESCAPE
        if state.paused
            state.restart = true
            update_game_map!(game)
            return
        else
            state.paused = true
            update_game_board!(game)
            update_game_map!(game)
        end
    end

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
        if move!(board_state, 0, -1, 0)
            game_map["signal"] = REDRAW_BOARD
        end
    elseif key == KEY_RIGHT
        if move!(board_state, 0, 1, 0)
            game_map["signal"] = REDRAW_BOARD
        end
    elseif key == KEY_B
        if move!(board_state, 0, 0, 1)
            game_map["signal"] = REDRAW_BOARD
        end
    elseif key == KEY_N
        if move!(board_state, 0, 0, -1)
            game_map["signal"] = REDRAW_BOARD
        end
    elseif key == KEY_DOWN
        if move!(board_state, 1, 0, 0)
            game_map["signal"] = REDRAW_BOARD
        end
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
        update_best_map!(game)
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
            update_best!(game)
        end
        update_game_map!(game)
        update_best_map!(game)
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
        update_best_map!(game)
    end
    if events.ground_touched
        state.won = true
        state.paused = true
        update_best!(game)
        update_game_map!(game)
    end
    reset!(events)
end

function handle_events(game::GameCleaner)
    state = game.state
    events = state.events

    if events.lines_completed > 0
        board_state = game.board_state
        board_state.lines_count += events.lines_completed
        board_state.score += SCORES[events.lines_completed]
        update_game_map!(game)
        update_best_map!(game)
    end
    if events.target_height_reached
        state.won = true
        state.paused = true
        update_best!(game)
        update_game_map!(game)
    end
    reset!(events)
end

################
# Update board #
################
function update_game_board!(game::Game)
    if game.state.paused && !(game.state.won || game.state.lost)
        game_map["board"] = get_random_board_map(game.board_state)
        game_map["next"] = get_random_tetromino_map()
    else
        game_map["board"] = get_board_map(game.board_state)
        game_map["next"] = get_tetromino_map(game.board_state.next_tetromino)
    end
end

########
# INIT #
########

game = nothing
game_map = QML.JuliaPropertyMap("score" => "0", "lines" => 0, "level" => 0,
                               "gameLost" => 0, "gameStarted" => 0, "gameRestart" => 0,
                                "gamePaused" => 0, "gameWon" => 0, "board" => [], "next" => [],
                                "signal" => 0)

best = nothing
best_map = QML.JuliaPropertyMap("linesCount" => 0, "score" => 0)


function init_game(game_type, level::Int32, height::Int32)
    global game, best
    if game_type == "unlimited"
        game = game_unlimited(level, height, best["unlimited"])
    elseif game_type == "25"
        game = game_25(level, height, best["25"])
    elseif game_type == "ground"
        game = game_ground(level, height, best["ground"])
    elseif game_type == "cleaner"
        game = game_cleaner(level, height, best["cleaner"])
    elseif game_type == "classic"
        game = game_unlimited(level, 0, best["unlimited"])
    else
        return
    end
    update_game_map!(game)
end

@qmlfunction init_game
@qmlfunction game_loop
@qmlfunction key_press

try
    open("juliatris.json", "r") do source
        global best
        best = JSON.parse(source)
        println(best)
    end
catch e
    println(e)
end

loadqml(qmlfile, game = game_map, TILE_SIZE = 20, best = best_map)
exec()

open("juliatris.json", "w") do dest
    println(best)
    JSON.print(dest, best)
end
