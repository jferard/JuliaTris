import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0

ColumnLayout {
    signal update()

    onUpdate: {
        nextCanvas.requestPaint()
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
        id: nextCanvas

        onPaint: {
            var ctx = nextCanvas.getContext('2d');
            ctx.fillRect(0, 0, 4*TILE_SIZE, 2*TILE_SIZE)
            var rows = game.next
            drawSquares(ctx, 0, 0, rows)
        }
    }
}
