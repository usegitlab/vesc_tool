/*
    Copyright 2018 Benjamin Vedder	benjamin@vedder.se

    This file is part of VESC Tool.

    VESC Tool is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    VESC Tool is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    */

import QtQuick 2.7
import QtQuick.Controls 2.10
import QtQuick.Layouts 1.3

import Vedder.vesc.vescinterface 1.0
import Vedder.vesc.commands 1.0
import Vedder.vesc.configparams 1.0
import Vedder.vesc.utility 1.0

Item {
    property var table: []

    property Commands mCommands: VescIf.commands()
    property ConfigParams mMcConf: VescIf.mcConfig()
    property ConfigParams mInfoConf: VescIf.infoConfig()
    property var dialogParent: ApplicationWindow.overlay

    function openDialog() {
        dialog.open()
    }

    function updateDisplay() {
        var txt = "Hall Table:\n"

        for (var i = 0;i < table.length;i++) {
            txt += "" + table[i]

            if (i != table.length - 1) {
                txt += ", "
            }
        }

        resultArea.text = txt
    }

    function testConnected() {
        if (VescIf.isPortConnected()) {
            return true
        } else {
            VescIf.emitMessageDialog(
                        "连接错误",
                        "VESC 未连接，请连接后再运行检测。",
                        false, false)
            return false
        }
    }

    Component.onCompleted: {
        updateDisplay()
    }

    Dialog {
        id: dialog
        standardButtons: Dialog.Close
        modal: true
        focus: true
        width: parent.width - 20
        height: column.height - 40
        closePolicy: Popup.CloseOnEscape

        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        x: 10
        y: Math.max((parent.height - height) / 2, 10)
        parent: dialogParent

        ScrollView {
            anchors.fill: parent
            clip: true
            contentWidth: parent.width

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                DoubleSpinBox {
                    id: currentBox
                    Layout.fillWidth: true
                    decimals: 2
                    realValue: 10.0
                    realFrom: 0.0
                    realTo: 200.0
                    prefix: "I: "
                    suffix: " A"
                }

                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        text: "帮助"
                        Layout.preferredWidth: 50
                        Layout.fillWidth: true
                        onClicked: {
                            VescIf.emitMessageDialog(
                                        mInfoConf.getLongName("help_foc_hall_detect"),
                                        mInfoConf.getDescription("help_foc_hall_detect"),
                                        true, true)
                        }
                    }

                    Button {
                        text: "检测"
                        Layout.preferredWidth: 50
                        Layout.fillWidth: true
                        onClicked: {
                            if (!testConnected()) {
                                return
                            }

                            detectDialog.open()
                        }
                    }
                }

                TextArea {
                    id: resultArea
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    readOnly: true
                    wrapMode: TextEdit.WordWrap
                    font.family: "DejaVuSansMono"
                }

                Button {
                    text: "应用并关闭"
                    Layout.fillWidth: true
                    onClicked: {
                        if (table.length != 8) {
                            VescIf.emitMessageDialog("应用错误",
                                                     "Hall table is empty.",
                                                     false, false)
                            return
                        }

                        for(var i = 0;i < 7;i++) {
                            mMcConf.updateParamInt("foc_hall_table__" + i, table[i])
                        }

                        VescIf.emitStatusMessage("Hall Sensor Parameters Applied", true)

                        dialog.close()
                    }
                }
            }
        }
    }

    Dialog {
        id: detectDialog
        standardButtons: Dialog.Ok | Dialog.Cancel
        modal: true
        focus: true
        width: parent.width - 20
        closePolicy: Popup.CloseOnEscape
        title: "检测 FOC 霍尔传感器参数"

        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        x: 10
        y: Math.max((parent.height - height) / 2, 10)
        parent: dialogParent

        Text {
            id: detectLambdaLabel
            color: Utility.getAppHexColor("lightText")
            verticalAlignment: Text.AlignVCenter
            anchors.fill: parent
            wrapMode: Text.WordWrap
            text:
                "This is going to turn the motor slowly. Make " +
                "sure that nothing is in the way."
        }

        onAccepted: {
            mCommands.measureHallFoc(currentBox.realValue)
        }
    }

    Connections {
        target: mCommands

        function onFocHallTableReceived(hall_table, res) {
            if (res !== 0) {
                VescIf.emitStatusMessage("收到错误 FOC 霍尔检测结果", false)
                VescIf.emitMessageDialog("收到错误 FOC 霍尔检测结果",
                                         "无法检测霍尔传感器，请确保所有连接" +
                                         "is connected properly.",
                                         false, false)
            } else {
                table = hall_table
                updateDisplay()
            }
        }
    }
}
