/*
    Copyright 2019 Benjamin Vedder	benjamin@vedder.se

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
import Vedder.vesc.utility 1.0

Item {
    property bool mLastDarkMode: false
    property var dialogParent: ApplicationWindow.overlay

    function openDialog() {
        mLastDarkMode = Utility.isDarkMode()
        dialog.open()
    }

    Dialog {
        id: dialog
        standardButtons: Dialog.Close
        modal: true
        focus: true
        title: "VESC Tool 设置"

        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        width: parent.width - 20
        closePolicy: Popup.CloseOnEscape

        x: 10
        y: Math.max((parent.height - height) / 2, 10)
        parent: dialogParent

        ScrollView {
            anchors.fill: parent

            ColumnLayout {
                anchors.fill: parent

                CheckBox {
                    id: imperialBox
                    Layout.fillWidth: true
                    text: "使用英制单位"
                    checked: VescIf.useImperialUnits()
                }

                CheckBox {
                    id: negativeSpeedBox
                    Layout.fillWidth: true
                    text: "使用负速度"
                    checked: VescIf.speedGaugeUseNegativeValues()
                }

                CheckBox {
                    id: screenOnBox
                    Layout.fillWidth: true
                    text: "保持屏幕常亮"
                    checked: VescIf.keepScreenOn()
                    visible: Qt.platform.os !== "ios"
                    enabled: Qt.platform.os !== "ios"
                }

                CheckBox {
                    id: screenRotBox
                    Layout.fillWidth: true
                    text: "允许屏幕旋转"
                    checked: VescIf.getAllowScreenRotation()
                    visible: Qt.platform.os !== "ios"
                    enabled: Qt.platform.os !== "ios"
                }

                CheckBox {
                    id: qmlUiBox
                    Layout.fillWidth: true
                    text: "连接时加载 QML 界面"
                    checked: VescIf.getLoadQmlUiOnConnect()
                }

                CheckBox {
                    id: qmlUiAskBox
                    Layout.fillWidth: true
                    text: "加载 QML 界面前询问"
                    checked: VescIf.askQmlLoad()
                }

                CheckBox {
                    id: reconnectLastCanBox
                    Layout.fillWidth: true
                    text: "连接时重新连接 CAN"
                    checked: VescIf.reconnectLastCan()
                }

                CheckBox {
                    id: scanCanConnectBox
                    Layout.fillWidth: true
                    text: "连接时扫描 CAN"
                    checked: VescIf.scanCanOnConnect()
                }

                CheckBox {
                    id: fwUpdateAvailableBox
                    Layout.fillWidth: true
                    text: "显示固件更新消息"
                    checked: VescIf.showFwUpdateAvailable()
                }

                CheckBox {
                    id: darkModeBox
                    Layout.fillWidth: true
                    text: "使用深色模式"
                    checked: Utility.isDarkMode()
                    onCheckedChanged: {
                        Utility.setDarkMode(checked)
                    }
                }
            }
        }

        onOpened: {
            imperialBox.checked = VescIf.useImperialUnits()
            negativeSpeedBox.checked = VescIf.speedGaugeUseNegativeValues()
            screenOnBox.checked = VescIf.keepScreenOn()
            screenRotBox.checked = VescIf.getAllowScreenRotation()
            qmlUiBox.checked = VescIf.getLoadQmlUiOnConnect()
            qmlUiAskBox.checked = VescIf.askQmlLoad()
            reconnectLastCanBox.checked = VescIf.reconnectLastCan()
            scanCanConnectBox.checked = VescIf.scanCanOnConnect()
            fwUpdateAvailableBox.checked = VescIf.showFwUpdateAvailable()
        }

        onClosed: {
            VescIf.setUseImperialUnits(imperialBox.checked)
            VescIf.setSpeedGaugeUseNegativeValues(negativeSpeedBox.checked)
            VescIf.setKeepScreenOn(screenOnBox.checked)
            VescIf.setAllowScreenRotation(screenRotBox.checked)
            VescIf.setLoadQmlUiOnConnect(qmlUiBox.checked)
            VescIf.setAskQmlLoad(qmlUiAskBox.checked)
            VescIf.setReconnectLastCan(reconnectLastCanBox.checked)
            VescIf.setScanCanOnConnect(scanCanConnectBox.checked)
            VescIf.setShowFwUpdateAvailable(fwUpdateAvailableBox.checked)
            VescIf.storeSettings()

            Utility.keepScreenOn(VescIf.keepScreenOn())

            if (VescIf.useWakeLock()) {
                VescIf.setWakeLock(VescIf.isPortConnected())
            }

            if (Utility.isDarkMode() !== mLastDarkMode) {
                darkChangedDialog.open()
            }

            VescIf.commands().emitEmptySetupValues()
        }
    }

    Dialog {
        id: darkChangedDialog
        standardButtons: Dialog.Yes | Dialog.No
        modal: true
        focus: true
        width: parent.width - 20
        closePolicy: Popup.CloseOnEscape
        title: "主题已更改"

        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        x: 10
        y: Math.max((parent.height - height) / 2, 10)
        parent: dialogParent

        Text {
            id: detectRlLabel
            color: Utility.getAppHexColor("lightText")
            verticalAlignment: Text.AlignVCenter
            anchors.fill: parent
            wrapMode: Text.WordWrap
            text:
                "主题已更改，需要重启 VESC Tool 才能生效。" +
                "是否立即关闭 VESC Tool？"
        }

        onAccepted: {
            Qt.quit()
        }
    }
}
