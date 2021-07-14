import QtQuick 2.0
import QtQuick.Window 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import org.julialang 1.0

Item {
    signal start(string x)

    onStart: {
        console.log(x)
        Julia.init_game()
        timer.running = true
    }

    RowLayout {
        spacing: 2*TILE_SIZE

        TetrisCanvas {
            id: tetrisCanvas
        }

        ColumnLayout {
            id: infosColumn
            Layout.alignment : Qt.AlignRight

            Lines {}

            Next {
                id: nextBox
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
            if (game.gameStarted != 0) {
                Julia.update_game()
            }
            tetrisCanvas.requestPaint();
            nextBox.update();
         }
    }
}
