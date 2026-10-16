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
    property real intLim: 0.0
    property real coupling: 0.0
    property var hallTable: []
    property int hallRes: -4
    property bool resultReceived: false
    property var dialogParent: ApplicationWindow.overlay

    property Commands mCommands: VescIf.commands()
    property ConfigParams mMcConf: VescIf.mcConfig()
    property ConfigParams mInfoConf: VescIf.infoConfig()

    function openDialog() {
        dialog.open()
    }

    function updateDisplay() {
        var txt = ""
        var i = 0

        txt +=
                "Integrator limit : " + parseFloat(intLim).toFixed(2) + "\n" +
                "反电动势耦合：" + parseFloat(coupling).toFixed(2) + "\n"

        if (hallRes == 0) {
            txt += "Detected hall sensor table:\n"
            for (i = 0;i < hallTable.length;i++) {
                txt += "" + hallTable[i]

                if (i != hallTable.length - 1) {
                    txt += ", "
                }
            }
        } else if (hallRes == -1) {
            txt += "Hall sensor detection failed:\n"
            for (i = 0;i < hallTable.length;i++) {
                txt += "" + hallTable[i]

                if (i != hallTable.length - 1) {
                    txt += ", "
                }
            }
        } else if (hallRes == -2) {
            txt += "WS2811 已启用，霍尔传感器不可用。"
        } else if (hallRes == -3) {
            txt += "编码器已启用，霍尔传感器不可用。"
        } else if (hallRes == -4) {
            txt += "检测到的霍尔传感器表："
        } else {
            txt += "未知霍尔错误：" + hallRes
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
                    realValue: 5.0
                    realFrom: 0.0
                    realTo: 200.0
                    prefix: "I: "
                    suffix: " A"
                }

                DoubleSpinBox {
                    id: dutyBox
                    Layout.fillWidth: true
                    decimals: 2
                    realValue: 0.05
                    realFrom: 0.0
                    realTo: 1.0
                    realStepSize: 0.01
                    prefix: "D: "
                }

                DoubleSpinBox {
                    id: erpmBox
                    Layout.fillWidth: true
                    decimals: 1
                    realValue: 450.0
                    realFrom: 0.0
                    realTo: 20000.0
                    realStepSize: 10.0
                    prefix: "\u03C9: "
                    suffix: " ERPM"
                }

                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        text: "帮助"
                        Layout.fillWidth: true
                        Layout.preferredWidth: 50
                        onClicked: {
                            VescIf.emitMessageDialog(
                                        mInfoConf.getLongName("help_bldc_detect"),
                                        mInfoConf.getDescription("help_bldc_detect"),
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
                    Layout.preferredHeight: 180
                    readOnly: true
                    font.family: "DejaVu Sans Mono"
                }

                Button {
                    text: "应用并关闭"
                    Layout.fillWidth: true
                    onClicked: {
                        if (!resultReceived) {
                            VescIf.emitMessageDialog("应用检测结果",
                                                     "未收到检测结果，请确保先运行检测。",
                                                     false, false)
                            return
                        }

                        mMcConf.updateParamDouble("sl_bemf_coupling_k", coupling)
                        mMcConf.updateParamDouble("sl_cycle_int_limit", intLim)

                        if (hallRes == 0) {
                            for(var i = 0;i < 7;i++) {
                                mMcConf.updateParamInt("hall_table__" + i, hallTable[i])
                            }
                        }

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
        title: "检测 BLDC 参数"

        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        x: 10
        y: Math.max((parent.height - height) / 2, 10)
        parent: dialogParent

        Text {
            id: detectLabel
            color: Utility.getAppHexColor("lightText")
            verticalAlignment: Text.AlignVCenter
            anchors.fill: parent
            wrapMode: Text.WordWrap
            text:
                "This is going to spin up the motor. Make " +
                "sure that nothing is in the way."
        }

        onAccepted: {
            mCommands.detectMotorParam(currentBox.realValue, erpmBox.realValue, dutyBox.realValue)
        }
    }

    Connections {
        target: mCommands

        function onBldcDetectReceived(param) {
            if (param.cycle_int_limit < 0.01 && param.bemf_coupling_k < 0.01) {
                VescIf.emitStatusMessage("收到错误检测结果", false)
                VescIf.emitMessageDialog("BLDC Detection",
                                         "收到错误检测结果",
                                         false, false)
            } else {
                VescIf.emitStatusMessage("已收到检测结果", true)
                intLim = param.cycle_int_limit
                coupling = param.bemf_coupling_k
                hallTable = param.hall_table
                hallRes = param.hall_res
                resultReceived = true

                updateDisplay()
            }
        }
    }
}
