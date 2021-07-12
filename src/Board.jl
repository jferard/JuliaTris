#=
Board:
- Julia version: 1.6.1
- Author: jferard
- Date: 2021-07-12
=#
module Board

export BoardCell, GameBoard, new_empty_board, position_allowed, merge_tetromino!, mark_lines!,
        remove_lines!, get_color, get_color_rows, get_tetro_i, get_tetro_j

using ..Colors
import ..Colors: get_color
using ..Tetrominos
using ..CurrentTetrominos
import ..CurrentTetrominos: get_cur_tetromino_arr

BoardCell = Union{Empty, Wall, Tetromino, Marked}

mutable struct GameBoard
    row_count::Int64 # walls included
    col_count::Int64 # wall included
    hidden_row_count::Int64
    rows::Matrix{<: Colored}
end

function new_empty_board(row_count, hidden_row_count, col_count)::GameBoard
    rows::Matrix{BoardCell} = fill(empty_square, row_count + hidden_row_count, col_count)
    for i in 1:row_count + hidden_row_count
        rows[i, 1] = wall
        rows[i, col_count] = wall
    end
    for j in 2:col_count - 1
        rows[row_count + hidden_row_count, j] = wall
    end
    board = GameBoard(row_count, col_count, hidden_row_count, rows)
    return board
end

function get_square(board::GameBoard, cell_i::Int64, cell_j::Int64)::BoardCell
    return board.rows[cell_i+board.hidden_row_count, cell_j]
end

function set_square(board::GameBoard, line_i::Int64, cell_j::Int64, cell::BoardCell)::BoardCell
    board.rows[line_i + board.hidden_row_count, cell_j] = cell
end

get_tetro_i(board::GameBoard)::Int64 = -2
get_tetro_j(board::GameBoard)::Int64 = floor(Int64, (board.col_count - TETROMINO_COL_COUNT) / 2) + 1

function position_allowed(board::GameBoard, tetromino::Tetromino, tetro_i::Int64, tetro_j::Int64,
                          orientation::Int64)::Bool
    arr = tetromino.arrays[orientation]
    for k in 1:TETROMINO_ROW_COUNT
        for l in 1:TETROMINO_COL_COUNT
            if arr[k, l] == 1
                cell_i = tetro_i + k - 1 # caveat here
                cell_j = tetro_j + l - 1
                if cell_i >= board.row_count || cell_j <= 1 || cell_j > board.col_count - 1
                    return false
                elseif get_square(board, cell_i, cell_j) != empty_square
                    return false
                end
            end
        end
    end
    return true
end

function merge_tetromino!(board::GameBoard, cur_tetromino::CurrentTetromino)
    arr = get_cur_tetromino_arr(cur_tetromino)
    tetro = cur_tetromino.tetromino
    for k in 1:TETROMINO_ROW_COUNT
        for l in 1:TETROMINO_COL_COUNT
            if arr[k, l] == 1
                cell_i = cur_tetromino.i + k - 1 # caveat here
                cell_j = cur_tetromino.j + l - 1
                if cell_i <= board.row_count && cell_j <= board.col_count
                    set_square(board, cell_i, cell_j, tetro)
                end
            end
        end
    end
end

function is_full_line(board::GameBoard, line_i::Int64)::Bool
    for cell_j in 1:board.col_count
        if get_square(board, line_i, cell_j) == empty_square
            return false
        end
    end
    return true
end

function mark_lines!(board::GameBoard)::Bool
    ret = false
    for line_i in 1:board.row_count - 1
        if is_full_line(board, line_i)
            for cell_j in 2:board.col_count-1
                set_square(board, line_i, cell_j, marked)
            end
            ret = true
        end
    end
    return ret
end

function is_marked_line(board::GameBoard, line_i::Int64)::Bool
    return get_square(board, line_i, 2) == marked
end

function remove_lines!(board::GameBoard)::Int64
    line_i = board.row_count - 1
    lines_count = 0
    while line_i >= 1
        if is_marked_line(board, line_i)
            for i in line_i + board.hidden_row_count:-1:2
                board.rows[i, :] = board.rows[i - 1, :]
            end
            board.rows[1, :] = [j == 1 || j == board.col_count ? wall : empty_square
                                for j in 1:board.col_count]
            lines_count += 1
        else
            line_i -= 1
        end
    end
    return lines_count
end

function get_color(board::GameBoard, cell_i, cell_j)::String
    return get_color(get_square(board, cell_i, cell_j))
end

end