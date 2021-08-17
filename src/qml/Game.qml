import QtQuick 2.0
import QtQuick.Window 2.0
import QtQuick.Controls 2.5
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
                }
                popEnter: Transition {
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
            canvasStack.push(information, StackView.PushTransition)
        }
    }

    function showGame() {
        if (canvasStack.currentItem != tetrisCanvas) {
            canvasStack.pop(StackView.PopTransition)
        }
    }


    Timer {
        id: timer
        interval: 16
        running: true
        repeat: true
        onTriggered: {
            if (game.gamePaused == 1) {
                // game.bestScore => stack.push()
                // game.bestScoreSeen => stack.pop() twice
                if (game.gameRestart == 1) {
                    stack.pop()
                    return;
                } if (game.gameLost == 1) {
                    information.text = "GAME OVER\nPress space"
                    showInformation()
                    return;
                }
                if (game.gameWon == 1) {
                    information.text = "Congratulations\nPress space"
                    showInformation()
                    return;
                } else if (game.gameStarted == 1) {
                    information.text = "Pause\nPress space"
                    showInformation()
                }
            } else if (game.gameStarted == 1) {
                showGame()
                Julia.game_loop()
            }

            tetrisCanvas.requestPaint();
            nextBox.update();
         }
    }

    TetrisCanvas {
        id: tetrisCanvas
        StackView.visible: true
    }

    Information {
        id: information
    }
}
