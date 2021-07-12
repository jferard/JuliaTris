#=
CurrentTetrominos:
- Julia version: 1.6.1
- Author: jferard
- Date: 2021-07-12
=#
module CurrentTetrominos

export CurrentTetromino, get_color, is_tetromino_there

using ..Colors
import ..Colors: get_color
using ..Tetrominos

mutable struct CurrentTetromino <: Colored
    i::Int64 # row
    j::Int64 # col
    tetromino::Tetromino
    orientation::Int64
end

get_color(c::CurrentTetromino) = get_color(c.tetromino)

get_cur_tetromino_arr(cur_tetromino::CurrentTetromino)::Matrix{Int64} = cur_tetromino.tetromino.arrays[cur_tetromino.orientation]

relative_to(cell_i, cell_j, cur_tetromino::CurrentTetromino)::Tuple{Int64, Int64} = (cell_i - cur_tetromino.i + 1, cell_j - cur_tetromino.j + 1)

function is_tetromino_there(cur_tetromino::CurrentTetromino, cell_i, cell_j)::Bool
    arr = get_cur_tetromino_arr(cur_tetromino)
    relative_i, relative_j = relative_to(cell_i, cell_j, cur_tetromino)
    if 1 <= relative_i <= TETROMINO_ROW_COUNT && 1 <= relative_j <= TETROMINO_COL_COUNT
        if arr[relative_i, relative_j] == 1
            return true
        end
    end
    return false
end

end