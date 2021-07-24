import QtQuick 2.0
import QtQuick.Window 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import org.julialang 1.0

Item {
    signal start(string gameType, int level, int height)

    onStart: {
        Julia.init_game(gameType, level, height)
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

            Level {}

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
                Julia.game_loop()
            }
            tetrisCanvas.requestPaint();
            nextBox.update();
         }
    }
}
