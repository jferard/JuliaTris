import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0

ColumnLayout {
    signal update()

    onUpdate: {
        infos_canvas.requestPaint()
    }

    Text {
        id: next
        width: 8*TILE_SIZE; height: 1*TILE_SIZE
        verticalAlignment : Text.AlignBottom
        horizontalAlignment: Text.AlignRight
        font.pointSize: 20
        text: "Next"
    }

    Canvas {
        width: 8*TILE_SIZE; height: 2*TILE_SIZE
        id: infos_canvas

        onPaint: {
            var ctx = infos_canvas.getContext('2d');
            ctx.fillRect(0, 0, 4*TILE_SIZE, 2*TILE_SIZE)
            var rows = game.next
            draw_squares(ctx, 0, 0, rows)
        }
    }
}
