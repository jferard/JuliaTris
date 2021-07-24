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
using Qt5QuickControls_jll
using JSON

include("Colors.jl")
include("Tetrominos.jl")
include("CurrentTetrominos.jl")
include("Board.jl")

using .Colors
import .Colors: get_color
using .Tetrominos
using .CurrentTetrominos
import .CurrentTetrominos: is_tetromino_there
using .Board
import .Board: position_allowed, merge_tetromino!, mark_lines!, remove_lines!, get_color,
                get_tetro_i, get_tetro_j

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


    function Events()
        return new(0)
    end
end

function reset(events::Events)
   events.lines_completed = 0
end

function create_empty_board(height)::GameBoard
    return new_empty_board(ROW_COUNT+1, HIDDEN_ROW_COUNT, COL_COUNT+2, height) # walls included
end

@enum GameType begin
    type_A = 1
    type_B = 2
end


mutable struct Game
    type::GameType
    events::Events
    base_level::Int64
    base_height::Int64
    base_lines_count::Int64
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
    over::Bool
end

game_A(base_level::Int32, base_height::Int32)::Game = Game(type_A, convert(Int64, base_level), convert(Int64, base_height), 0)

game_B(base_level::Int32, base_height::Int32)::Game = Game(type_B, convert(Int64, base_level), convert(Int64, base_height), 25)

function Game(type::GameType, base_level::Int64, base_height::Int64, base_lines_count::Int64)
    events = Events()
    board = create_empty_board(base_height)
    tetro_i = get_tetro_i(board)
    tetro_j = get_tetro_j(board)
    cur_tetromino = CurrentTetromino(tetro_i, tetro_j, random_tetromino(), 1)
    next_tetromino = random_tetromino()
    speed = MAX_SPEED +  SPEED_UP * (MAX_LEVEL - base_level)
    return Game(type, events, base_level, base_height, base_lines_count, base_level, 0, speed, board, cur_tetromino,
                next_tetromino, base_lines_count, 0, false, false, false)
end


function updateGameMap!(game::Game)
    global gameMap
    gameMap["level"] = game.cur_level
    gameMap["lines"] = game.base_lines_count
    gameMap["score"] = game.score
    gameMap["gameStarted"] = Int(game.started)
    gameMap["gameOver"] = Int(game.over)
end

function updateBestMap!(game::Game)
    global bestMap
    if game.base_lines_count > bestMap["linesCount"]
        bestMap["linesCount"] = game.base_lines_count
    end
    if game.score > bestMap["score"]
        bestMap["score"] = game.score
    end
end

function reset!(game::Game)
    game.cur_level = game.base_level
    game.board = create_empty_board(game.base_height)
    game.round = 0
    game.speed = MAX_SPEED +  SPEED_UP * (MAX_LEVEL - game.base_level)
    tetro_i = get_tetro_i(game.board)
    tetro_j = get_tetro_j(game.board)
    game.cur_tetromino = CurrentTetromino(tetro_i, tetro_j, random_tetromino(), 1)
    game.next_tetromino = random_tetromino()
    game.base_lines_count = game.base_lines_count
    game.score = 0
    game.marked = false
    game.started = true
    game.over = false
    updateGameMap!(game)
end

function next_tetromino!(game::Game)
    tetromino = game.next_tetromino
    tetro_i = get_tetro_i(game.board)
    tetro_j = get_tetro_j(game.board)
    if position_allowed(game.board, tetromino, tetro_i, tetro_j, 1)
        game.cur_tetromino = CurrentTetromino(tetro_i, tetro_j, tetromino, 1)
        game.next_tetromino = random_tetromino()
    else
        game.started = false
        game.over = true
        updateGameMap!(game)
    end
end

function move!(game::Game, delta_i::Int64, delta_j::Int64, delta_orientation::Int64)::Bool
    cur_tetromino = game.cur_tetromino
    new_i = cur_tetromino.i + delta_i
    new_j = cur_tetromino.j + delta_j
    new_orientation = cur_tetromino.orientation + delta_orientation
    max = size(cur_tetromino.tetromino.arrays, 1)
    if new_orientation > max
        new_orientation -= max
    elseif new_orientation <= 0
        new_orientation += max
    end

    if position_allowed(game.board, cur_tetromino.tetromino,
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

function remove_lines!(game::Game)
    game.events.lines_completed = remove_lines!(game.board)
end

function fall!(game::Game)
    cur_tetromino = game.cur_tetromino
    game.round = 0
    if !move!(game, 1, 0, 0)
        merge_tetromino!(game.board, game.cur_tetromino)
        if mark_lines!(game.board)
            game.marked = true
        end
        next_tetromino!(game)
        updateGameBoard!(game)
    end
end

function key_press(key::Int32)
    global game
    if game == nothing
        return
    end

    if !game.started
        if key == KEY_SPACE
            reset!(game)
            updateGameBoard!(game)
        end
        return
    end

    cur_tetromino = game.cur_tetromino
    if key == KEY_LEFT
        move!(game, 0, -1, 0)
    elseif key == KEY_RIGHT
        move!(game, 0, 1, 0)
    elseif key == KEY_B
        move!(game, 0, 0, 1)
    elseif key == KEY_N
        move!(game, 0, 0, -1)
    elseif key == KEY_DOWN
        move!(game, 1, 0, 0)
    end
end

function game_loop()
    global game
    handle_events(game)

    if game.over
        return
    end
    game.round += 1
    if game.round >= game.speed
        if game.marked
            remove_lines!(game)
            # TODO: check if the ground was reached or if the board is clean.
            game.marked = false
        else
            fall!(game)
        end
    end
    updateGameMap!(game)
    updateGameBoard!(game)
end

function handle_events(game::Game)
    if game.type == type_A
        handle_events_A(game, game.events)
    elseif game.type == type_B
        handle_events_B(game, game.events)
    end
end

function handle_events_A(game::Game, events::Events)
    if events.lines_completed > 0
        game.base_lines_count += events.lines_completed
        game.score += SCORES[events.lines_completed]
        if game.base_lines_count % 10 == 0
             lines_level = floor(Int64, game.base_lines_count // 10)
             if game.cur_level < lines_level && lines_level <= MAX_LEVEL
                game.speed -= SPEED_UP
                game.cur_level += 1
             end
        end
        updateGameMap!(game)
        updateBestMap!(game)
    end
    reset(events)
end

function handle_events_B(game::Game, events::Events)
    if events.lines_completed > 0
        game.base_lines_count -= events.lines_completed
        game.score += SCORES[events.lines_completed]
        if game.base_lines_count <= 0
            game.base_lines_count == 0
            game.over = true
            # win
        end
        updateGameMap!(game)
        updateBestMap!(game)
    end
    reset(events)
end

################
# Update board #
################
function updateGameBoard!(game::Game)
    gameMap["next"] = get_next_tetromino(game)
    gameMap["board"] = get_board(game)
end

function get_board(game::Game)::Vector{Vector{String}}
    board = game.board
    color_rows = [[BLACK for _ in 1:board.col_count]
                   for _ in 1:board.row_count]
    for cell_i in 1:board.row_count
        for cell_j in 1:board.col_count
            color = get_color(game, cell_i, cell_j)
            color_rows[cell_i][cell_j] = color
        end
    end
    return color_rows
end

function get_next_tetromino(game::Game)::Vector{Vector{String}}
    arr = game.next_tetromino.arrays[1]
    color = game.next_tetromino.color

    return [[arr[i, j] == 1 ? color : "black" for j in 1:TETROMINO_COL_COUNT] for i in 3:TETROMINO_ROW_COUNT]
end

function get_color(game::Game, cell_i, cell_j)::String
    if is_tetromino_there(game.cur_tetromino, cell_i, cell_j)
        return get_color(game.cur_tetromino)
    else
       return get_color(game.board, cell_i, cell_j)
    end
end


########
# INIT #
########

game = nothing
gameMap = QML.JuliaPropertyMap("score" => "0", "lines" => 0, "level" => 0,
                               "gameOver" => 0, "gameStarted" => 0, "board" => [],
                               "next" => []
                               )

function init_game(game_type, level::Int32, height::Int32)
    global game
    if game_type == type_A
        game = game_A(level, height)
    else
        game = game_B(level, height)
    end
    updateGameMap!(game)
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
