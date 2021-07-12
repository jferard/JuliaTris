#=
colored:
- Julia version: 1.6.1
- Author: jferard
- Date: 2021-07-12
=#
module Colors

export Colored, get_color, DARK_GRAY, GRAY, BLACK, RED, GREEN, BLUE, AQUA, YELLOW, MAGENTA, ORANGE

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

end
