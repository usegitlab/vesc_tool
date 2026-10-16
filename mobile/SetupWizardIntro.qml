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
import QtGraphicalEffects 1.0

import Vedder.vesc.vescinterface 1.0
import Vedder.vesc.configparams 1.0
import Vedder.vesc.utility 1.0

Item {
    property ConfigParams mInfoConf: VescIf.infoConfig()
    property var dialogParent: ApplicationWindow.overlay

    function openDialog() {
        dialog.open()
    }

    Component.onCompleted: {
        introText.text = mInfoConf.getDescription("wizard_startup_intro")
        usageText.text = mInfoConf.getDescription("wizard_startup_usage")
        warrantyText.text = mInfoConf.getDescription("wizard_startup_warranty")
        conclusionText.text = mInfoConf.getDescription("wizard_startup_conclusion")
    }

    Dialog {
        id: dialog
        modal: true
        focus: true
        width: parent.width - 10 - notchLeft - notchRight
        height: parent.height - 10
        closePolicy: Popup.NoAutoClose
        x: 5 + (notchLeft + notchRight) / 2
        y: 5
        parent: dialogParent
        bottomMargin: 0
        rightMargin: 0
        padding: 10

        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        StackLayout {
            id: stackLayout
            anchors.fill: parent

            Item {
                Text {
                    id: introText
                    color: Utility.getAppHexColor("lightText")
                    linkColor: "lightblue"
                    verticalAlignment: Text.AlignVCenter
                    anchors.fill: parent
                    wrapMode: Text.WordWrap
                    textFormat: Text.RichText
                    onLinkActivated: {
                        Qt.openUrlExternally(link)
                    }
                }
            }

            Item {
                ColumnLayout {
                    anchors.fill: parent

                    ScrollView {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        clip: true
                        contentWidth: availableWidth

                        Text {
                            id: usageText
                            color: Utility.getAppHexColor("lightText")
                            linkColor: "lightblue"
                            verticalAlignment: Text.AlignVCenter
                            width: parent.parent.width - 20
                            wrapMode: Text.WordWrap
                            textFormat: Text.RichText
                            onLinkActivated: {
                                Qt.openUrlExternally(link)
                            }
                        }
                    }

                    CheckBox {
                        id: acceptUsageBox
                        Layout.fillWidth: true
                        text: "是的，我理解并接受"

                        onToggled: {
                            updateButtonsEnabled()
                        }
                    }
                }
            }

            Item {
                ColumnLayout {
                    anchors.fill: parent

                    ScrollView {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        clip: true
                        contentWidth: parent.width - 20

                        Text {
                            id: warrantyText
                            color: Utility.getAppHexColor("lightText")
                            linkColor: "lightblue"
                            verticalAlignment: Text.AlignVCenter
                            width: parent.parent.width - 20
                            wrapMode: Text.WordWrap
                            textFormat: Text.RichText
                            onLinkActivated: {
                                Qt.openUrlExternally(link)
                            }
                        }
                    }

                    CheckBox {
                        id: acceptWarrantyBox
                        Layout.fillWidth: true
                        text: "是的，我理解并接受"

                        onToggled: {
                            updateButtonsEnabled()
                        }
                    }
                }
            }

            Item {
                Text {
                    id: conclusionText
                    color: Utility.getAppHexColor("lightText")
                    linkColor: "lightblue"
                    verticalAlignment: Text.AlignVCenter
                    anchors.fill: parent
                    wrapMode: Text.WordWrap
                    textFormat: Text.RichText
                    onLinkActivated: {
                        Qt.openUrlExternally(link)
                    }
                }
            }
        }

        header: Rectangle {
            color: Utility.getAppHexColor("lightText")
            height: tabBar.height

            TabBar {
                id: tabBar
                currentIndex: stackLayout.currentIndex
                anchors.fill: parent
                implicitWidth: 0
                clip: true
                enabled: false

                background: Rectangle {
                    opacity: 1
                    color: Utility.getAppHexColor("lightBackground")
                }

                property int buttons: 3
                property int buttonWidth: 120

                TabButton {
                    text: "简介"
                    width: Math.max(tabBar.buttonWidth, tabBar.width / tabBar.buttons)
                }
                TabButton {
                    text: "使用情况"
                    width: Math.max(tabBar.buttonWidth, tabBar.width / tabBar.buttons)
                }
                TabButton {
                    text: "保修"
                    width: Math.max(tabBar.buttonWidth, tabBar.width / tabBar.buttons)
                }
                TabButton {
                    text: "结论"
                    width: Math.max(tabBar.buttonWidth, tabBar.width / tabBar.buttons)
                }
            }
        }

        footer: RowLayout {
            spacing: 0
            Button {
                id: prevButton
                Layout.fillWidth: true
                Layout.preferredWidth: 500
                text: "取消"
                flat: true

                onClicked: {
                    if (stackLayout.currentIndex == 0) {
                        cancelDialog.open()
                    } else {
                        stackLayout.currentIndex--
                    }

                    updateButtonText()
                }
            }

            Button {
                id: nextButton
                Layout.fillWidth: true
                Layout.preferredWidth: 500
                text: "下一步"
                flat: true

                onClicked: {
                    if (stackLayout.currentIndex == (stackLayout.count - 1)) {
                        VescIf.setIntroDone(true)
                        dialog.close()
                    } else {
                        stackLayout.currentIndex++
                    }

                    updateButtonText()
                }
            }
        }
    }

    Dialog {
        id: cancelDialog
        standardButtons: Dialog.Ok | Dialog.Close
        modal: true
        focus: true
        width: parent.width - 20 - notchLeft - notchRight
        height: Math.min(implicitHeight, parent.height - 40)
        closePolicy: Popup.CloseOnEscape
        parent: dialogParent

        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        ScrollView {
            anchors.fill: parent
            clip: true
            contentWidth: parent.width - 20

            Text {
                id: resultLabel
                color: Utility.getAppHexColor("lightText")
                verticalAlignment: Text.AlignVCenter
                anchors.fill: parent
                wrapMode: Text.WordWrap
                text: "您必须完成简介才能使用 VESC Tool。"
            }
        }

        onRejected: {
            Qt.quit()
        }
    }

    function updateButtonText() {
        if (stackLayout.currentIndex == (stackLayout.count - 1)) {
            nextButton.text = "完成"
        } else {
            nextButton.text = "Next"
        }

        if (stackLayout.currentIndex == 0) {
            prevButton.text = "取消"
        } else {
            prevButton.text = "上一步"
        }

        updateButtonsEnabled()
    }

    function updateButtonsEnabled() {
        if (stackLayout.currentIndex == 0) {
            nextButton.enabled = true
        } else if (stackLayout.currentIndex == 1) {
            nextButton.enabled = acceptUsageBox.checked
        } else if (stackLayout.currentIndex == 2) {
            nextButton.enabled = acceptWarrantyBox.checked
        } else if (stackLayout.currentIndex == 3) {
            nextButton.enabled = true
        }
    }
}
