#=
BoardState:
- Julia version: 1.6.1
- Author: jferard
- Date: 2021-07-26
=#
module BoardStates

export GameModel, BoardState, new_board_state, next_tetromino!, move!, get_board_map,
        get_random_board_map

using ..Board
using ..Tetrominos
using ..CurrentTetrominos

const MAX_LEVEL = 20
const SPEED_UP = 2
const MAX_SPEED = 4 # actually, this is a min!
const ROW_COUNT = 20
const HIDDEN_ROW_COUNT = TETROMINO_ROW_COUNT - 1
const COL_COUNT = 10

mutable struct GameModel
    level::Int64
    height::Int64
    lines_count::Int64
    target_height::Int64
end

function create_empty_board(height)::GameBoard
    return new_empty_board(ROW_COUNT+1, HIDDEN_ROW_COUNT, COL_COUNT+2, height) # walls included
end

mutable struct BoardState
    cur_level::Int64
    round::Int64
    speed::Int64
    board::GameBoard
    cur_tetromino::CurrentTetromino
    next_tetromino::Tetromino
    lines_count::Int64
    score::Int64
    marked::Bool
end

function new_board_state(model::GameModel)::BoardState
    board = create_empty_board(model.height)
    tetro_i = get_tetro_i(board)
    tetro_j = get_tetro_j(board)
    cur_tetromino = CurrentTetromino(tetro_i, tetro_j, random_tetromino(), 1)
    next_tetromino = random_tetromino()
    speed = MAX_SPEED +  SPEED_UP * (MAX_LEVEL - model.level)
    state = BoardState(model.level, 0, speed, board, cur_tetromino,
                next_tetromino, model.lines_count, 0, false)
end

function next_tetromino!(board_state::BoardState)
    tetromino = board_state.next_tetromino
    tetro_i = get_tetro_i(board_state.board)
    tetro_j = get_tetro_j(board_state.board)
    if position_allowed(board_state.board, tetromino, tetro_i, tetro_j, 1)
        board_state.cur_tetromino = CurrentTetromino(tetro_i, tetro_j, tetromino, 1)
        board_state.next_tetromino = random_tetromino()
    else
        board_state.lost = true
        board_state.paused = true
        update_game_map!(game)
    end
end

function move!(board_state::BoardState, delta_i::Int64, delta_j::Int64, delta_orientation::Int64)::Bool
    cur_tetromino = board_state.cur_tetromino
    new_i = cur_tetromino.i + delta_i
    new_j = cur_tetromino.j + delta_j
    new_orientation = cur_tetromino.orientation + delta_orientation
    max = size(cur_tetromino.tetromino.arrays, 1)
    if new_orientation > max
        new_orientation -= max
    elseif new_orientation <= 0
        new_orientation += max
    end

    if position_allowed(board_state.board, cur_tetromino.tetromino,
                            new_i, new_j, new_orientation)
        cur_tetromino.i = new_i
        cur_tetromino.j = new_j
        cur_tetromino.orientation = new_orientation
        return true
    else
        return false
    end
end

function get_board_map(state::BoardState)::Vector{Vector{String}}
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

function get_color(board_state::BoardState, cell_i, cell_j)::String
    if is_tetromino_there(board_state.cur_tetromino, cell_i, cell_j)
        return get_color(board_state.cur_tetromino)
    else
       return get_color(board_state.board, cell_i, cell_j)
    end
end

function get_random_board_map(board_state::BoardState)::Vector{Vector{String}}
    row_count = board_state.board.row_count
    col_count = board_state.board.col_count
    color_rows = [[BLACK for _ in 1:col_count] for _ in 1:row_count]
    for cell_i in 1:row_count
        for cell_j in 1:col_count
            color = fixed_color(cell_i, cell_j)
            color_rows[cell_i][cell_j] = color
        end
    end
    return color_rows
end

end