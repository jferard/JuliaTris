#=
colored:
- Julia version: 1.6.1
- Author: jferard
- Date: 2021-07-12
=#
module Colors

export Colored, get_color, DARK_GRAY, GRAY, BLACK, RED, GREEN, BLUE, AQUA, YELLOW, MAGENTA, ORANGE,
        Wall, Empty, Marked, wall, empty_square, marked

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

abstract type Colored end
function get_color(c::Colored)::String end

struct Wall <: Colored end
get_color(w::Wall)::String = DARK_GRAY

struct Empty <: Colored end
get_color(e::Empty)::String = BLACK

round = 0

struct Marked <: Colored end
function get_color(m::Marked)::String
    global round
    round += 1
    return [RED, ORANGE, YELLOW, GREEN, BLUE, MAGENTA][floor(Int, round / 30) % 6 + 1]
end

wall = Wall()
empty_square = Empty()
marked = Marked()

end
