# JuliaTris
Copyright (C) 2021 J. Férard <https://github.com/jferard>

A Tetris clone in Julia/Qt under GPLv3

## Summary
I wanted to learn a bit of Julia and a bit of Qt. So I wrote this little Tetris clone.

    $ julia --project src/JuliaTris.jl 

Screenshot:

![JuliaTris](https://user-images.githubusercontent.com/10564095/130656876-6f7e7939-c5ea-4f89-b3f6-e7013ace8572.png)

## Game
I added two modes to the classic "Type A" (unlimited) and "Type B" (25 lines) modes:
* "Touch ground": one tetromino must touch the ground despite the garbage blocks present at the beginning
* "Cleaner": same as "Touch ground", but the game ends when the height is less or equal to one.

## About Julia
I won't write another blog post about Julia. Just a few remarks (this is my first program in Julia):
* arrays and matrix starting at 1 are not a gift you want to place a tertromino on the game board. If `tetromino_start_x` is the x of the tetromino and `cur_x` the pos of the current block inside the tetromino, then `block_x = tetromino_start_x + cur_x - 1` (in any other language: `block_x = tetromino_start_x + cur_x`).
* I was suprised by the amount of runtime errors. My IDE (IntelliJ) did not provide warnings about thing as simple as the incorrect number of call arguments. Hence, programming was unusually tedious.
* Multiple dispatch is really (I mean: really) convenient.

## About Qt
Just a one remark (this is my first program in Qt):
* I didn't know that QML was like JavaScript: there's almost no learning curve.
* QtQuick was easy to use.



