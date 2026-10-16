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
    property real res: 0.0
    property real ind: 0.0
    property real lambda: 0.0
    property real kp: 0.0
    property real ki: 0.0
    property real gain: 0.0

    property Commands mCommands: VescIf.commands()
    property ConfigParams mMcConf: VescIf.mcConfig()
    property ConfigParams mInfoConf: VescIf.infoConfig()
    property var dialogParent: ApplicationWindow.overlay

    function openDialog() {
        dialog.open()
    }

    function updateDisplay() {
        resultArea.text =
                "电阻：" + parseFloat(res * 1e3).toFixed(2) + " m\u03A9\n" +
                "L      : " + parseFloat(ind * 1e6).toFixed(2) + " µH\n" +
                "\u03BB      : " + parseFloat(lambda * 1e3).toFixed(3) + " mWb\n" +
                "KP     : " + parseFloat(kp).toFixed(4) + "\n" +
                "KI     : " + parseFloat(ki).toFixed(2) + "\n" +
                "增益：" + parseFloat(gain).toFixed(2)
    }

    function calcKpKi() {
        if (res < 1e-10) {
            VescIf.emitMessageDialog("计算错误",
                                     "电阻为 0，请先进行测量。",
                                     false, false)
            return;
        }

        if (ind < 1e-10) {
            VescIf.emitMessageDialog("计算错误",
                                     "L is 0. Please measure it first.",
                                     false, false)
            return;
        }

        // https://e2e.ti.com/blogs_/b/motordrivecontrol/archive/2015/07/20/teaching-your-pi-controller-to-behave-part-ii
        var tc = tcBox.realValue * 1e-6
        var bw = 1.0 / tc
        kp = ind * bw;
        ki = res * bw;

        updateDisplay()
    }

    function calcGain() {
        if (lambda < 1e-10) {
            VescIf.emitMessageDialog("计算错误",
                                     "\u03BB is 0. Please measure it first.",
                                     false, false)
            return;
        }

        if (res < 1e-10) {
            VescIf.emitMessageDialog("计算错误",
                                     "电阻为 0，请先进行测量。",
                                     false, false)
            return;
        }

        gain = 1.0e-3 / (lambda * lambda)

        updateDisplay()
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
                    realValue: mMcConf.getParamDouble("l_current_max") / 3.0
                    realFrom: 0.0
                    realTo: 200.0
                    prefix: "I: "
                    suffix: " A"
                }

                DoubleSpinBox {
                    id: dutyBox
                    Layout.fillWidth: true
                    decimals: 2
                    realValue: 0.3
                    realFrom: 0.0
                    realTo: 1.0
                    realStepSize: 0.1
                    prefix: "D: "
                }

                DoubleSpinBox {
                    id: erpmBox
                    Layout.fillWidth: true
                    decimals: 1
                    realValue: 2000.0
                    realFrom: 0.0
                    realTo: 20000.0
                    realStepSize: 10.0
                    prefix: "\u03C9: "
                    suffix: " ERPM/s"
                }

                DoubleSpinBox {
                    id: tcBox
                    Layout.fillWidth: true
                    decimals: 1
                    realValue: 1000.0
                    realFrom: 0.0
                    realTo: 1000000.0
                    realStepSize: 100.0
                    prefix: "T: "
                    suffix: " µS"
                }

                Button {
                    text: "帮助"
                    Layout.fillWidth: true
                    onClicked: {
                        VescIf.emitMessageDialog(
                                    mInfoConf.getLongName("help_foc_detect"),
                                    mInfoConf.getDescription("help_foc_detect"),
                                    true, true)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        text: "检测 R&L"
                        Layout.preferredWidth: 50
                        Layout.fillWidth: true
                        onClicked: {
                            if (!testConnected()) {
                                return
                            }

                            detectRlDialog.open()
                        }
                    }

                    Button {
                        text: "DETECT \u03BB"
                        font.capitalization: Font.MixedCase
                        Layout.preferredWidth: 50
                        Layout.fillWidth: true
                        onClicked: {
                            if (!testConnected()) {
                                return
                            }

                            if (res < 1e-9) {
                                VescIf.emitMessageDialog("检测",
                                                         "电阻为 0，请先进行测量。",
                                                         false, false)
                            } else {
                                detectLambdaDialog.open()
                            }
                        }
                    }
                }

                Button {
                    text: "CALCULATE KP, KI AND \u03BB"
                    font.capitalization: Font.MixedCase
                    Layout.fillWidth: true
                    onClicked: {
                        calcKpKi()
                        calcGain()
                    }
                }

                TextArea {
                    id: resultArea
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    readOnly: true
                    font.family: "DejaVu Sans Mono"
                }

                Button {
                    text: "应用并关闭"
                    Layout.fillWidth: true
                    onClicked: {
                        if (res < 1e-10) {
                            VescIf.emitMessageDialog("应用错误",
                                                     "电阻为 0，请先进行测量。",
                                                     false, false)
                            return
                        }

                        if (ind < 1e-10) {
                            VescIf.emitMessageDialog("应用错误",
                                                     "L is 0. Please measure it first.",
                                                     false, false)
                            return
                        }

                        if (lambda < 1e-10) {
                            VescIf.emitMessageDialog("应用错误",
                                                     "\u03BB is 0. Please measure it first.",
                                                     false, false)
                            return
                        }

                        calcKpKi()
                        calcGain()

                        mMcConf.updateParamDouble("foc_motor_r", res)
                        mMcConf.updateParamDouble("foc_motor_l", ind)
                        mMcConf.updateParamDouble("foc_motor_flux_linkage", lambda)
                        mMcConf.updateParamDouble("foc_current_kp", kp)
                        mMcConf.updateParamDouble("foc_current_ki", ki)
                        mMcConf.updateParamDouble("foc_observer_gain", gain * 1e6)

                        dialog.close()
                    }
                }
            }
        }
    }

    Dialog {
        id: detectRlDialog
        standardButtons: Dialog.Ok | Dialog.Cancel
        modal: true
        focus: true
        width: parent.width - 20
        closePolicy: Popup.CloseOnEscape
        title: "测量 R & L"

        x: 10
        y: Math.max((parent.height - height) / 2, 10)
        parent: dialogParent

        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        Text {
            id: detectRlLabel
            color: Utility.getAppHexColor("lightText")
            verticalAlignment: Text.AlignVCenter
            anchors.fill: parent
            wrapMode: Text.WordWrap
            text:
                "测量 R & L 时电机会发出噪声，但" +
                "not rotate. These noises are completely normal, so don't unplug " +
                "anything unless you see smoke."
        }

        onAccepted: {
            mCommands.measureRL()
        }
    }

    Dialog {
        id: detectLambdaDialog
        standardButtons: Dialog.Ok | Dialog.Cancel
        modal: true
        focus: true
        width: parent.width - 20
        closePolicy: Popup.CloseOnEscape
        title: "警告"

        x: 10
        y: Math.max((parent.height - height) / 2, 10)
        parent: dialogParent

        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        Text {
            anchors.fill: parent
            id: detectLambdaLabel
            color: Utility.getAppHexColor("lightText")
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
            text:
                "<font color=\"red\">Warning: </font>" +
                "This is going to spin up the motor. Make " +
                "sure that nothing is in the way."
        }

        onAccepted: {
            mCommands.measureLinkageOpenloop(currentBox.realValue, erpmBox.realValue,
                                             dutyBox.realValue, res, ind)
        }
    }

    Connections {
        target: mCommands

        function onMotorRLReceived(r, l, ld_lq_diff) {
            if (r < 1e-9 && l < 1e-9) {
                VescIf.emitStatusMessage("收到错误 FOC 检测结果", false)
                VescIf.emitMessageDialog("检测结果错误",
                                         "无法测量电机电阻和电感。",
                                         false, false)
            } else {
                VescIf.emitStatusMessage("已收到 FOC 检测结果", true)
                res = r
                ind = l * 1e-6
                calcKpKi()
            }
        }

        function onMotorLinkageReceived(flux_linkage) {
            if (flux_linkage < 1e-9) {
                VescIf.emitStatusMessage("收到错误 FOC 检测结果", false)
                VescIf.emitMessageDialog("检测结果错误",
                                         "无法正确测量磁通量，请调整" +
                                         "the start parameters according to the help text and try again.",
                                         false, false)
            } else {
                VescIf.emitStatusMessage("已收到 FOC 检测结果", true)
                lambda = flux_linkage
                calcGain()
            }
        }
    }

    Connections {
        target: mMcConf

        function onParamChangedDouble(src, name, newParam) {
            if (name === "l_current_max") {
                currentBox.realValue = newParam / 3.0
            }
        }
    }
}
