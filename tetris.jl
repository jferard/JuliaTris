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

const DARK_GRAY = "dark gray"
const GRAY = "gray"
const BLACK = "black"
const RED = "red"
const GREEN = "green"
const BLUE = "blue"
const AQUA = "aqua"
const YELLOW = "yellow"
const MAGENTA = "magenta"
const ORANGE = "orange"

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

struct Tetromino
    color::String
    arrays::Vector{Matrix{Int64}}
end

const TETROMINO_ROW_COUNT = 4
const TETROMINO_COL_COUNT = 4

wall_tetromino = Tetromino(DARK_GRAY, [])
no_tetromino = Tetromino(BLACK, [])
marked_tetromino = Tetromino(GRAY, [])

# https://en.wikipedia.org/wiki/Tetromino#One-sided_tetrominoes
I_tetromino = Tetromino(AQUA, [
    [0 0 0 0
     0 0 0 0
     1 1 1 1
     0 0 0 0],
    [0 1 0 0
     0 1 0 0
     0 1 0 0
     0 1 0 0],
])

O_tetromino = Tetromino(YELLOW, [
    [0 0 0 0
     0 0 0 0
     0 1 1 0
     0 1 1 0],
])

T_tetromino = Tetromino(MAGENTA, [
    [0 0 0 0
     0 0 0 0
     1 1 1 0
     0 1 0 0],
    [0 0 0 0
     0 1 0 0
     0 1 1 0
     0 1 0 0],
    [0 0 0 0
     0 1 0 0
     1 1 1 0
     0 0 0 0],
    [0 0 0 0
     0 1 0 0
     1 1 0 0
     0 1 0 0],
])

J_tetromino = Tetromino(BLUE, [
    [0 0 0 0
     0 0 0 0
     1 1 1 0
     0 0 1 0],
    [0 0 0 0
     0 1 1 0
     0 1 0 0
     0 1 0 0],
    [0 0 0 0
     0 0 0 0
     1 0 0 0
     1 1 1 0],
    [0 0 0 0
     0 1 0 0
     0 1 0 0
     1 1 0 0],
])

L_tetromino = Tetromino(ORANGE, [
    [0 0 0 0
     0 0 0 0
     1 1 1 0
     1 0 0 0],
    [0 0 0 0
     0 1 0 0
     0 1 0 0
     0 1 1 0],
    [0 0 0 0
     0 0 1 0
     1 1 1 0
     0 0 0 0],
    [0 0 0 0
     1 1 0 0
     0 1 0 0
     0 1 0 0],
])

S_tetromino = Tetromino(RED, [
    [0 0 0 0
     0 0 0 0
     0 1 1 0
     0 0 1 1],
    [0 0 0 0
     0 0 1 0
     0 1 1 0
     0 1 0 0],
])

Z_tetromino = Tetromino(GREEN, [
    [0 0 0 0
     0 0 0 0
     0 1 1 0
     1 1 0 0],
    [0 0 0 0
     0 1 0 0
     0 1 1 0
     0 0 1 0],
])

mutable struct CurrentTetromino
    i::Int64 # row
    j::Int64 # col
    tetromino::Tetromino
    orientation::Int64
end

function get_cur_tetromino_arr(cur_tetromino::CurrentTetromino)::Matrix{Int64}
    return cur_tetromino.tetromino.arrays[cur_tetromino.orientation]
end

function relative_to(cell_i, cell_j, cur_tetromino::CurrentTetromino)::Tuple{Int64, Int64}
    # start at 1
    return (cell_i - cur_tetromino.i + 1, cell_j - cur_tetromino.j + 1)
end

const ROW_COUNT = 20
const HIDDEN_ROW_COUNT = TETROMINO_ROW_COUNT - 1
const COL_COUNT = 10
const BASE_SPEED = 3 + 2 * 20
const SIDE = 20

function create_board()::Matrix{Tetromino}
    board = fill(no_tetromino, ROW_COUNT + 1 + HIDDEN_ROW_COUNT, COL_COUNT + 2)
    for i in 1:ROW_COUNT + 1 + HIDDEN_ROW_COUNT
        board[i, 1] = wall_tetromino
        board[i, COL_COUNT + 2] = wall_tetromino
    end
    for j in 1:COL_COUNT + 1
        board[ROW_COUNT + 1 + HIDDEN_ROW_COUNT, j] = wall_tetromino
    end
    return board
end

function random_tetromino()::Tetromino
    return [I_tetromino, O_tetromino, T_tetromino, J_tetromino, L_tetromino, S_tetromino, Z_tetromino][rand(1:7)]
end

mutable struct Game
    round::Int64
    speed::Int64
    board::Matrix{Tetromino}
    cur_tetromino::CurrentTetromino
    next_tetromino::Tetromino
    lines_count::Int64
    score::Int64
    started::Bool
    over::Bool

    function Game()
        board = create_board()
        tetro_i = 1
        tetro_j::Int64 = (size(board)[2] - TETROMINO_COL_COUNT) / 2 + 1
        cur_tetromino = CurrentTetromino(tetro_i, tetro_j, random_tetromino(), 1)
        next_tetromino = random_tetromino()
        return new(0, BASE_SPEED, board, cur_tetromino, next_tetromino, 0, 0, false, false)
    end
end

function reset(game::Game)
    game.board = create_board()
    game.round = 0
    game.speed = BASE_SPEED
    tetro_i = 1
    tetro_j::Int64 = (size(game.board)[2] - TETROMINO_COL_COUNT) / 2 + 1
    game.cur_tetromino = CurrentTetromino(tetro_i, tetro_j, random_tetromino(), 1)
    game.next_tetromino = random_tetromino()
    game.lines_count = 0
    game.score = 0
    game.started = true
    game.over = false
    gameMap["game_started"] = 1
    gameMap["game_over"] = 0
end

function next_tetromino(game::Game)
    tetromino = game.next_tetromino
    tetro_i = 1
    tetro_j::Int64 = (size(game.board)[2] - TETROMINO_COL_COUNT) / 2 + 1
    if position_allowed(game, tetro_i, tetro_j, 1)
        game.cur_tetromino = CurrentTetromino(tetro_i, tetro_j, tetromino, 1)
        game.next_tetromino = random_tetromino()
    else
        game.started = false
        game.over = true
        gameMap["game_started"] = 0
        gameMap["game_over"] = 1
    end
end


keys = Vector{Int32}

function position_allowed(game::Game, tetro_i::Int64, tetro_j::Int64, orientation::Int64)::Bool
    row_count, col_count = size(game.board)
    arr = game.cur_tetromino.tetromino.arrays[orientation]
    for k in 1:TETROMINO_ROW_COUNT
        for l in 1:TETROMINO_COL_COUNT
            if arr[k, l] == 1
                cell_i = tetro_i + k - 1 # caveat here
                cell_j = tetro_j + l - 1
                if cell_i <= 0
                    return true
                elseif cell_i > row_count || cell_j <= 0 || cell_j > col_count
                    return false
                elseif game.board[cell_i, cell_j] != no_tetromino
                    return false
                end
            end
        end
    end
    return true
end

function merge_tetromino(game::Game)
    cur_tetromino = game.cur_tetromino
    arr = get_cur_tetromino_arr(cur_tetromino)
    row_count, col_count = size(game.board)
    for k in 1:TETROMINO_ROW_COUNT
        for l in 1:TETROMINO_COL_COUNT
            if arr[k, l] == 1
                cell_i = cur_tetromino.i + k - 1 # caveat here
                cell_j = cur_tetromino.j + l - 1
                if cell_i <= row_count && cell_j <= col_count
                    game.board[cell_i, cell_j] = cur_tetromino.tetromino
                end
            end
        end
    end
end

function is_full_line(line::Vector{Tetromino})::Bool
    # use any
    for cell_j in 1:size(line, 1)
        if line[cell_j] == no_tetromino
            return false
        end
    end
    return true
end

function is_marked_line(line::Vector{Tetromino})::Bool
    for cell_j in 1:size(line, 1)
        if line[cell_j] != marked_tetromino
            return false
        end
    end
    return true
end

function mark_lines(game::Game)
    row_count, col_count = size(game.board)
    for cell_i in row_count - 1:-1:1
        if is_full_line(game.board[cell_i, 2:col_count - 1])
            for cell_j in 2:col_count - 1
                game.board[cell_i, cell_j] = marked_tetromino
            end
        end
    end
end

function remove_lines(game::Game)
    row_count, col_count = size(game.board)
    cell_i = row_count - 1
    lines_count = 0
    while cell_i >= 1
        if is_marked_line(game.board[cell_i, 2:col_count - 1])
            for i in cell_i:-1:2
                game.board[i, :] = game.board[i - 1, :]
            end
            game.board[1, :] = [i == 1 || i == col_count ? wall_tetromino : no_tetromino for i in 1:col_count]
            lines_count += 1
        else
            cell_i -= 1
        end
    end
    if lines_count >= 1
        game.lines_count += lines_count
        gameMap["lines"] = game.lines_count
        game.score += [1000, 4000, 16000, 64000][lines_count]
        gameMap["score"] = string(game.score)
        if game.lines_count % 10 == 0 && game.speed >= 3
            game.speed -= 2
        end
    end
end

function move(game::Game)
    if game.over
        return
    end
    remove_lines(game)
    game.round += 1
    cur_tetromino = game.cur_tetromino
    if game.round >= game.speed
        game.round = 0
        if position_allowed(game, cur_tetromino.i + 1, cur_tetromino.j, cur_tetromino.orientation)
            cur_tetromino.i += 1
        else
            merge_tetromino(game)
            mark_lines(game)
            # check for line
            # check for failure
            next_tetromino(game)
            gameMap["next"] = get_next_tetromino()
        end
    end
end

function is_tetromino_there(game::Game, cell_i, cell_j)::Bool
    arr = get_cur_tetromino_arr(game.cur_tetromino)
    relative_i, relative_j = relative_to(cell_i, cell_j, game.cur_tetromino)
    if 1 <= relative_i <= TETROMINO_ROW_COUNT && 1 <= relative_j <= TETROMINO_COL_COUNT
        if arr[relative_i, relative_j] == 1
            return true
        end
    end
    return false
end

function get_color(game::Game, cell_i, cell_j)::String
    if is_tetromino_there(game, cell_i, cell_j)
        return game.cur_tetromino.tetromino.color
    else
        return game.board[cell_i, cell_j].color
    end
end

function key_press(key::Int32)
    global game
    if !game.started
        if key == KEY_SPACE
            reset(game)
        end
        return
    end

    cur_tetromino = game.cur_tetromino
    if key == KEY_LEFT
        if position_allowed(game, cur_tetromino.i, cur_tetromino.j - 1, cur_tetromino.orientation)
            cur_tetromino.j -= 1
        end
    elseif key == KEY_RIGHT
        if position_allowed(game, cur_tetromino.i,cur_tetromino.j + 1, cur_tetromino.orientation)
            cur_tetromino.j += 1
        end
    elseif key == KEY_B
        orientation = cur_tetromino.orientation + 1
        if orientation > size(cur_tetromino.tetromino.arrays, 1)
            orientation = 1
        end
        if position_allowed(game, cur_tetromino.i, cur_tetromino.j, orientation)
            cur_tetromino.orientation = orientation
        end
    elseif key == KEY_N
        orientation = cur_tetromino.orientation - 1
        if orientation <= 0
            orientation = size(cur_tetromino.tetromino.arrays, 1)
        end
        if position_allowed(game, cur_tetromino.i, cur_tetromino.j, orientation)
            cur_tetromino.orientation = orientation
        end
    elseif key == KEY_DOWN
        while position_allowed(game, cur_tetromino.i + 1, cur_tetromino.j, cur_tetromino.orientation)
            cur_tetromino.i += 1
        end
    end
end

function update_game()
    global game
    move(game)
    gameMap["board"] = get_board()
end

function get_board()::Vector{Vector{String}}
    global game

    row_count, col_count = size(game.board)
    board = [["black" for _ in 1:col_count] for _ in 1+HIDDEN_ROW_COUNT:row_count]
    for cell_i in 1+HIDDEN_ROW_COUNT:row_count
        for cell_j in 1:col_count
            color = get_color(game, cell_i, cell_j)
            for y in cell_i*SIDE:(cell_i + 1) * SIDE
                for x in cell_j*SIDE:(cell_j + 1) * SIDE
                    board[cell_i-HIDDEN_ROW_COUNT][cell_j] = color
                end
            end
        end
    end

    return board
end

function get_next_tetromino()::Vector{Vector{String}}
    global game

    arr = game.next_tetromino.arrays[1]
    color = game.next_tetromino.color

    return [[arr[i, j] == 1 ? color : "black" for j in 1:TETROMINO_COL_COUNT] for i in 3:TETROMINO_ROW_COUNT]
end

game = Game()
gameMap = QML.JuliaPropertyMap("score" => "0", "lines" => 0, "level" => 1,
                               "game_over" => 0, "game_started" => 0, "board" => get_board(),
                               "next" => get_next_tetromino()
                               )

@qmlfunction update_game
@qmlfunction key_press

mutable struct Test
    name::String
    cost::Int64
end


loadqml(qmlfile, game=gameMap, TILE_SIZE=20)
exec()