import QtQuick 2.0
import QtQuick.Window 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import org.julialang 1.0

Item {
    signal start()

    onStart: {
        console.log("start")
        timer.running = true
    }

    RowLayout {
        spacing: 2*TILE_SIZE

        TetrisCanvas {
            id: tetris_canvas
        }

        ColumnLayout {
            id: col_infos
            Layout.alignment : Qt.AlignRight

            Lines {}

            Next {
                id: next_box
            }

            Score {}

            Best {}

            Help {}
        }
    }

    Timer {
        id: timer
        interval: 16
        running: true
        repeat: true
        onTriggered: {
            tetris_canvas.requestPaint();
            next_box.update();
         }
    }
}
