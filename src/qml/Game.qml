import QtQuick 2.0
import QtQuick.Window 2.0
import QtQuick.Controls 2.2
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

        StackView {
            id: canvasStack
            width: 12*TILE_SIZE; height: 21*TILE_SIZE
            focus: true
            Component.onCompleted: {
                canvasStack.push(tetrisCanvas)
                canvasStack.push(information)
                tetrisCanvas.StackView.visible = true
            }
            pushEnter: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 0
                    to:1
                    duration: 200
                }
            }
            pushExit: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 1
                    to:0
                    duration: 200
                }
            }
            popEnter: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 0
                    to:1
                    duration: 200
                }
            }
            popExit: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 1
                    to:0
                    duration: 200
                }
            }
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

    function showInformation() {
        if (canvasStack.currentItem != information) {
            canvasStack.clear()
            canvasStack.push(tetrisCanvas)
            canvasStack.push(information)
        }
    }

    function showGame() {
        if (canvasStack.currentItem != tetrisCanvas) {
            canvasStack.clear()
            canvasStack.push(information)
            canvasStack.push(tetrisCanvas)
        }
    }


    Timer {
        id: timer
        interval: 16
        running: true
        repeat: true
        onTriggered: {
            if (game.gameStarted == 0) {
                showInformation()
                return
            } else if (game.gamePaused != 0) {
                showInformation()
            } else {
                showGame()
            }

            Julia.game_loop()
            tetrisCanvas.requestPaint();
            nextBox.update();
         }
    }

    TetrisCanvas {
        id: tetrisCanvas
        visible: true
        StackView.visible: true
    }

    Information {
        id: information
        visible: true
        StackView.visible: true
    }
}
