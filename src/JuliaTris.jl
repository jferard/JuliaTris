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

using .Colors
import .Colors: get_color
using .Tetrominos
import .Tetrominos: fixed_color
using .CurrentTetrominos
import .CurrentTetrominos: is_tetromino_there
using .Board
import .Board: position_allowed, merge_tetromino!, mark_lines!, remove_lines!, get_color,
                get_tetro_i, get_tetro_j, get_height

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

const ROW_COUNT = 20
const HIDDEN_ROW_COUNT = TETROMINO_ROW_COUNT - 1
const COL_COUNT = 10
const MAX_LEVEL = 20
const SPEED_UP = 2
const MAX_SPEED = 4 # actually, this is a min!
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

function create_empty_board(height)::GameBoard
    return new_empty_board(ROW_COUNT+1, HIDDEN_ROW_COUNT, COL_COUNT+2, height) # walls included
end

@enum GameType begin
    type_A = 1
    type_B = 2
end

mutable struct GameModel
    type::GameType
    level::Int64
    height::Int64
    lines_count::Int64
    target_height::Int64
end

mutable struct GameState
    events::Events
    cur_level::Int64
    round::Int64
    speed::Int64
    board::GameBoard
    cur_tetromino::CurrentTetromino
    next_tetromino::Tetromino
    lines_count::Int64
    score::Int64
    marked::Bool
    started::Bool
    paused::Bool
    over::Bool
end

function GameState(model::GameModel)
    events = Events()
    board = create_empty_board(model.height)
    tetro_i = get_tetro_i(board)
    tetro_j = get_tetro_j(board)
    cur_tetromino = CurrentTetromino(tetro_i, tetro_j, random_tetromino(), 1)
    next_tetromino = random_tetromino()
    speed = MAX_SPEED +  SPEED_UP * (MAX_LEVEL - model.level)
    state = GameState(events, model.level, 0, speed, board, cur_tetromino,
                next_tetromino, model.lines_count, 0, false, false, false, false)
end

abstract type Game end

mutable struct GameUnlimited <: Game
    model::GameModel
    state::GameState
end

mutable struct Game25 <: Game
    model::GameModel
    state::GameState
end

mutable struct GameGround <: Game
    model::GameModel
    state::GameState
end

mutable struct GameCleaner <: Game
    model::GameModel
    state::GameState
end

game_unlimited(base_level::Int32, base_height::Int32)::Game = GameUnlimited(type_A, convert(Int64, base_level), convert(Int64, base_height), 0)

game_25(base_level::Int32, base_height::Int32)::Game = Game25(type_B, convert(Int64, base_level), convert(Int64, base_height), 25)

game_ground(base_level::Int32, base_height::Int32)::Game = GameGround(type_B, convert(Int64, base_level), convert(Int64, base_height), 0)

game_cleaner(base_level::Int32, base_height::Int32)::Game = GameCleaner(type_B, convert(Int64, base_level), convert(Int64, base_height), 0)


function GameUnlimited(type::GameType, base_level::Int64, base_height::Int64, base_lines_count::Int64)::Game
    model = GameModel(type, base_level, base_height, base_lines_count, -1)
    state = GameState(model)
    return GameUnlimited(model, state)
end

function Game25(type::GameType, base_level::Int64, base_height::Int64, base_lines_count::Int64)::Game
    model = GameModel(type, base_level, base_height, base_lines_count, -1)
    state = GameState(model)
    return Game25(model, state)
end

function GameGround(type::GameType, base_level::Int64, base_height::Int64, base_lines_count::Int64)::Game
    model = GameModel(type, base_level, base_height, base_lines_count, -1)
    state = GameState(model)
    return GameGround(model, state)
end

function GameCleaner(type::GameType, base_level::Int64, base_height::Int64, base_lines_count::Int64)::Game
    model = GameModel(type, base_level, base_height, base_lines_count, 2)
    state = GameState(model)
    return GameCleaner(model, state)
end


function updateGameMap!(state::GameState)
    global gameMap
    gameMap["level"] = state.cur_level
    gameMap["lines"] = state.lines_count
    gameMap["score"] = state.score
    gameMap["gameStarted"] = Int(state.started)
    gameMap["gamePaused"] = Int(state.paused)
    gameMap["gameOver"] = Int(state.over)
end

function updateBestMap!(state::GameState)
    global bestMap
    if state.lines_count > bestMap["linesCount"]
        bestMap["linesCount"] = state.lines_count
    end
    if state.score > bestMap["score"]
        bestMap["score"] = state.score
    end
end

function reset!(game::Game)
    reset!(game.state, game.model)
end

function reset!(state::GameState, model::GameModel)
    state.cur_level = model.level
    state.round = 0
    state.speed = MAX_SPEED +  SPEED_UP * (MAX_LEVEL - state.cur_level)
    state.board = create_empty_board(model.height)
    tetro_i = get_tetro_i(state.board)
    tetro_j = get_tetro_j(state.board)
    state.cur_tetromino = CurrentTetromino(tetro_i, tetro_j, random_tetromino(), 1)
    state.next_tetromino = random_tetromino()
    state.lines_count = model.lines_count
    state.score = 0
    state.marked = false
    state.started = true
    state.paused = false
    state.over = false
    updateGameMap!(state)
end

function next_tetromino!(state::GameState)
    tetromino = state.next_tetromino
    tetro_i = get_tetro_i(state.board)
    tetro_j = get_tetro_j(state.board)
    if position_allowed(state.board, tetromino, tetro_i, tetro_j, 1)
        state.cur_tetromino = CurrentTetromino(tetro_i, tetro_j, tetromino, 1)
        state.next_tetromino = random_tetromino()
    else
        state.started = false
        state.over = true
        updateGameMap!(state)
    end
end

function move!(state::GameState, delta_i::Int64, delta_j::Int64, delta_orientation::Int64)::Bool
    cur_tetromino = state.cur_tetromino
    new_i = cur_tetromino.i + delta_i
    new_j = cur_tetromino.j + delta_j
    new_orientation = cur_tetromino.orientation + delta_orientation
    max = size(cur_tetromino.tetromino.arrays, 1)
    if new_orientation > max
        new_orientation -= max
    elseif new_orientation <= 0
        new_orientation += max
    end

    if position_allowed(state.board, cur_tetromino.tetromino,
                            new_i, new_j, new_orientation)
        cur_tetromino.i = new_i
        cur_tetromino.j = new_j
        cur_tetromino.orientation = new_orientation
        return true
    else
        return false
    end
end

SCORES = [40, 100, 300, 1000]

function remove_lines!(state::GameState)
    state.events.lines_completed = remove_lines!(state.board)
end

function fall!(state::GameState)
    cur_tetromino = state.cur_tetromino
    if !move!(state, 1, 0, 0)
        merge_tetromino!(state.board, state.cur_tetromino)
        if mark_lines!(state.board)
            state.marked = true
        end
        check_height!(game)
        check_ground!(state)
        next_tetromino!(state)
        updateGameBoard!(state)
    end
end

function check_height!(game::Game)
    if get_height(game.state.board) <= game.model.target_height
        game.state.events.target_height_reached = true
    end
end    

function check_ground!(state::GameState)
    if ground_touched(state.board, state.cur_tetromino)
        state.events.ground_touched = true
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

    if key == KEY_SPACE
        if !state.started
            reset!(game)
            updateGameBoard!(state)
            updateGameMap!(state)
        else
            state.paused = !state.paused
            updateGameMap!(state)
        end
    end

    if !state.started || state.paused
        return
    end

    cur_tetromino = state.cur_tetromino
    if key == KEY_LEFT
        move!(state, 0, -1, 0)
    elseif key == KEY_RIGHT
        move!(state, 0, 1, 0)
    elseif key == KEY_B
        move!(state, 0, 0, 1)
    elseif key == KEY_N
        move!(state, 0, 0, -1)
    elseif key == KEY_DOWN
        move!(state, 1, 0, 0)
    end
end

function game_loop()
    global game
    handle_events(game)

    state = game.state
    if state.over || state.paused
        updateGameBoard!(state)
        return
    end
    state.round += 1
    if state.round >= state.speed
        if state.marked
            remove_lines!(state)
            # TODO: check if the ground was reached or if the board is clean.
            state.marked = false
            check_height!(game)
        else
            fall!(state)
        end
        state.round = 0
    end
    updateGameMap!(state)
    updateGameBoard!(state)
end

function handle_events(game::GameUnlimited)
    state = game.state
    events = game.state.events

    if events.lines_completed > 0
        state.lines_count += events.lines_completed
        state.score += SCORES[events.lines_completed]
        if state.lines_count % 10 == 0
             lines_level = floor(Int64, state.lines_count // 10)
             if state.cur_level < lines_level && lines_level <= MAX_LEVEL
                state.speed -= SPEED_UP
                state.cur_level += 1
             end
        end
        updateGameMap!(state)
        updateBestMap!(state)
    end
    reset!(events)
end

function handle_events(game::Game25)
    state = game.state
    events = game.state.events

    if events.lines_completed > 0
        state.lines_count -= events.lines_completed
        state.score += SCORES[events.lines_completed]
        if state.lines_count <= 0
            state.lines_count == 0
            state.over = true
            # win
        end
        updateGameMap!(state)
        updateBestMap!(state)
    end
    reset!(events)
end

function handle_events(game::GameGround)
    state = game.state
    events = game.state.events

    if events.lines_completed > 0
        state.lines_count += events.lines_completed
        state.score += SCORES[events.lines_completed]
        updateGameMap!(state)
        updateBestMap!(state)
    end
    if events.ground_touched
        state.over = true
        println("WIN!")
        # win
    end
    reset!(events)
end

function handle_events(game::GameCleaner)
    state = game.state
    events = game.state.events

    if events.lines_completed > 0
        state.lines_count -= events.lines_completed
        state.score += SCORES[events.lines_completed]
        updateGameMap!(state)
        updateBestMap!(state)
    end
    if events.target_height_reached
        state.over = true
        println("WIN!")
        # win
    end
    reset!(events)
end

################
# Update board #
################
function updateGameBoard!(state::GameState)
    if state.paused
        gameMap["board"] = get_random_board_map(state)
        gameMap["next"] = get_random_tetromino_map()
    else
        gameMap["board"] = get_board_map(state)
        gameMap["next"] = get_tetromino_map(state.next_tetromino)
    end
end

function get_random_board_map(state::GameState)::Vector{Vector{String}}
    row_count = state.board.row_count
    col_count = state.board.col_count
    color_rows = [[BLACK for _ in 1:col_count] for _ in 1:row_count]
    for cell_i in 1:row_count
        for cell_j in 1:col_count
            color = fixed_color(cell_i, cell_j)
            color_rows[cell_i][cell_j] = color
        end
    end
    return color_rows
end

function get_random_tetromino_map()::Vector{Vector{String}}
    return [[fixed_color(i, j) for j in 1:TETROMINO_COL_COUNT] for i in 3:TETROMINO_ROW_COUNT]
end

function get_board_map(state::GameState)::Vector{Vector{String}}
    row_count = state.board.row_count
    col_count = state.board.col_count
    color_rows = [[BLACK for _ in 1:col_count] for _ in 1:row_count]
    for cell_i in 1:row_count
        for cell_j in 1:col_count
            color = get_color(state, cell_i, cell_j)
            color_rows[cell_i][cell_j] = color
        end
    end
    return color_rows
end

function get_tetromino_map(next_tetromino::Tetromino)::Vector{Vector{String}}
    arr = next_tetromino.arrays[1]
    color = next_tetromino.color

    return [[arr[i, j] == 1 ? color : "black" for j in 1:TETROMINO_COL_COUNT] for i in 3:TETROMINO_ROW_COUNT]
end

function get_color(state::GameState, cell_i, cell_j)::String
    if is_tetromino_there(state.cur_tetromino, cell_i, cell_j)
        return get_color(state.cur_tetromino)
    else
       return get_color(state.board, cell_i, cell_j)
    end
end


########
# INIT #
########

game = nothing
gameMap = QML.JuliaPropertyMap("score" => "0", "lines" => 0, "level" => 0,
                               "gameOver" => 0, "gameStarted" => 0, "gamePaused" => 0, "board" => [],
                               "next" => []
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
    updateGameMap!(game.state)
end

@qmlfunction init_game
@qmlfunction game_loop
@qmlfunction key_press

bestMap = QML.JuliaPropertyMap("linesCount" => 0, "score" => 0)
try
    open("juliatris.json", "r") do source
        global bestMap
        best = JSON.parse(source)
        bestMap = QML.JuliaPropertyMap(best)
    end
catch e
    println(e)
end

loadqml(qmlfile, game=gameMap, TILE_SIZE=20, best=bestMap)
exec()

open("juliatris.json", "w") do dest
    JSON.print(dest, bestMap)
end
