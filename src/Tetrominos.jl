#=
Tetrominos:
- Julia version: 1.6.1
- Author: jferard
- Date: 2021-07-12
=#
module Tetrominos

export Tetromino, get_color, TETROMINO_ROW_COUNT, TETROMINO_COL_COUNT, I_tetromino, O_tetromino,
        T_tetromino, J_tetromino, L_tetromino, S_tetromino, Z_tetromino, random_tetromino

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

random_tetromino()::Tetromino = [I_tetromino, O_tetromino, T_tetromino, J_tetromino, L_tetromino, S_tetromino, Z_tetromino][rand(1:7)]

end