#=
Tetrominos:
- Julia version: 1.6.1
- Author: jferard
- Date: 2021-07-12
=#
module Tetrominos

export Tetromino, get_color, TETROMINO_ROW_COUNT, TETROMINO_COL_COUNT, I_tetromino, O_tetromino,
        T_tetromino, J_tetromino, L_tetromino, S_tetromino, Z_tetromino, random_tetromino,
        random_tetromino_or_empty, get_tetromino_map, get_random_tetromino_map

using ..Colors
import ..Colors: get_color

struct Tetromino <: Colored
    color::String
    arrays::Vector{Matrix{Int64}}
end
get_color(t::Tetromino)::String = t.color

const TETROMINO_ROW_COUNT = 4
const TETROMINO_COL_COUNT = 4

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

TETROMINOS = [I_tetromino, O_tetromino, T_tetromino, J_tetromino, L_tetromino, S_tetromino, Z_tetromino]

random_tetromino()::Tetromino = TETROMINOS[rand(1:7)]

random_tetromino_or_empty()::Colored = if rand() < 0.5
       empty_square
    else
       random_tetromino()
    end

fixed_color(i, j) = TETROMINOS[((i-1)*TETROMINO_COL_COUNT+(j-1)) % 7 + 1].color

function get_tetromino_map(next_tetromino::Tetromino)::Vector{Vector{String}}
    arr = next_tetromino.arrays[1]
    color = next_tetromino.color

    return [[arr[i, j] == 1 ? color : "black" for j in 1:TETROMINO_COL_COUNT] for i in 3:TETROMINO_ROW_COUNT]
end

function get_random_tetromino_map()::Vector{Vector{String}}
    return [[fixed_color(i, j) for j in 1:TETROMINO_COL_COUNT] for i in 3:TETROMINO_ROW_COUNT]
end

end
