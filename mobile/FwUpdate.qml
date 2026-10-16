/*
    Copyright 2017 - 2023 Benjamin Vedder	benjamin@vedder.se

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

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.3 as Dl

import Vedder.vesc.vescinterface 1.0
import Vedder.vesc.commands 1.0
import Vedder.vesc.configparams 1.0
import Vedder.vesc.fwhelper 1.0
import Vedder.vesc.utility 1.0

Item {
    property alias currentPage: swipeView.currentIndex
    property alias swipeOrientation: swipeView.orientation
    property alias pageIndicatorVisible: indicator.visible

    property Commands mCommands: VescIf.commands()
    property ConfigParams mInfoConf: VescIf.infoConfig()
    property bool isHorizontal: width > height
    property bool showUploadAllButton: true
    anchors.fill: parent

    FwHelper {
        id: fwHelper
    }

    GridLayout {
        anchors.fill: parent
        columns: isHorizontal ? 2 : 1
        rows: isHorizontal ? 1 : 2

        RowLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.column: isHorizontal ? 1 : 0
            Layout.row: 0
            Layout.preferredWidth: isHorizontal ? parent.width/2 : parent.width
            spacing: 0

            Rectangle {
                color: Utility.getAppHexColor("normalBackground")
                width: 16
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter |  Qt.AlignVCenter

                PageIndicator {
                    id: indicator
                    count: swipeView.count
                    currentIndex: swipeView.currentIndex
                    anchors.centerIn: parent
                    rotation: 90
                }
            }

            SwipeView {
                id: swipeView
                enabled: true
                clip: true

                Layout.fillWidth: true
                Layout.fillHeight: true
                orientation: Qt.Vertical

                contentItem: ListView {
                    model: swipeView.contentModel
                    interactive: swipeView.interactive
                    currentIndex: swipeView.currentIndex

                    spacing: swipeView.spacing
                    orientation: swipeView.orientation
                    snapMode: ListView.SnapOneItem
                    boundsBehavior: Flickable.StopAtBounds

                    highlightRangeMode: ListView.StrictlyEnforceRange
                    preferredHighlightBegin: 0
                    preferredHighlightEnd: 0
                    highlightMoveDuration: 250

                    maximumFlickVelocity: 8 * (swipeView.orientation ===
                                               Qt.Horizontal ? width : height)
                }

                Page {
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        anchors.topMargin: 10

                        Rectangle {
                            Layout.fillWidth: true
                            height: 30;
                            border.width: 0
                            color: "#55" + Utility.getAppHexColor("darkAccent").slice(1)
                            border.color: Utility.getAppHexColor("lightestBackground")

                            Text {
                                anchors.centerIn: parent
                                color: Utility.getAppHexColor("lightText")
                                text: "包含文件"
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        Button {
                            id: latestUpdateButton
                            text: "下载最新版本"
                            Layout.fillWidth: true

                            onClicked: {
                                latestUpdateButton.enabled = false
                                workaroundTimerDlLatest.start()
                            }

                            Timer {
                                id: workaroundTimerDlLatest
                                interval: 0
                                repeat: false
                                running: false
                                onTriggered: {
                                    VescIf.downloadFwLatest()
                                    VescIf.downloadConfigs()
                                    fwHelper.reloadLatest()
                                    updateFwText()
                                    latestUpdateButton.enabled = true
                                }
                            }
                        }

                        ProgressBar {
                            id: dlProgLatest
                            Layout.fillWidth: true
                        }

                        Text {
                            id: fwIncludedText
                            visible: false

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            textFormat: Text.RichText
                            color: Utility.getAppHexColor("lightText")
                            wrapMode: Text.WordWrap
                        }

                        ColumnLayout {
                            id: fwIncludedColumn

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.margins: 0

                            Item {
                                // Spacer
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }

                            Text {
                                color: Utility.getAppHexColor("lightText")
                                Layout.fillWidth: true
                                height: 30;
                                text: "硬件"
                                horizontalAlignment: Text.AlignHCenter
                            }

                            ComboBox {
                                id: hwBox
                                Layout.preferredHeight: 48
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                                textRole: "key"
                                model: ListModel {
                                    id: hwItems
                                }

                                Component.onCompleted: {
                                    updateFwText()
                                }

                                onCurrentIndexChanged: {
                                    updateFws()
                                }

                                function updateFws() {
                                    if (hwItems.rowCount() === 0) {
                                        return
                                    }

                                    var fws = fwHelper.getFirmwares(hwItems.get(hwBox.currentIndex).value)

                                    fwItems.clear()

                                    for (var name in fws) {
                                        if (name.toLowerCase().indexOf("vesc_default.bin") !== -1) {
                                            fwItems.insert(0, { key: name, value: fws[name] })
                                        } else {
                                            fwItems.append({ key: name, value: fws[name] })
                                        }
                                    }

                                    fwBox.currentIndex = 0
                                }
                            }

                            Text {
                                color: Utility.getAppHexColor("lightText")
                                Layout.fillWidth: true
                                height: 30;
                                text: "固件"
                                horizontalAlignment: Text.AlignHCenter
                            }

                            ComboBox {
                                id: fwBox
                                Layout.preferredHeight: 48
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                                textRole: "key"
                                model: ListModel {
                                    id: fwItems
                                }
                            }

                            Button {
                                text: "显示更新日志"
                                Layout.fillWidth: true

                                onClicked: {
                                    VescIf.emitMessageDialog(
                                                "固件更新日志",
                                                Utility.fwChangeLog(),
                                                true)
                                }
                            }

                            Item {
                                // Spacer
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }
                        }
                    }
                }

                Page {
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        anchors.topMargin: 10

                        Rectangle {
                            Layout.fillWidth: true
                            height: 30;
                            border.width: 0
                            color: "#55" + Utility.getAppHexColor("darkAccent").slice(1)

                            border.color: "#00000000"

                            Text {
                                anchors.centerIn: parent
                                color: Utility.getAppHexColor("lightText")
                                text: "自定义文件"
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        Item {
                            // Spacer
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }

                        TextInput {
                            color: Utility.getAppHexColor("lightText")
                            id: customFwText
                            Layout.fillWidth: true
                        }

                        Button {
                            text: "选择文件..."
                            Layout.fillWidth: true

                            onClicked: {
                                if (Utility.requestFilePermission()) {
                                    fileDialog.close()
                                    fileDialog.open()
                                } else {
                                    VescIf.emitMessageDialog(
                                                "文件权限",
                                                "无法请求文件系统权限。",
                                                false, false)
                                }
                            }
                        }

                        Item {
                            // Spacer
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }
                    }

                    Dl.FileDialog {
                        id: fileDialog
                        title: "选择固件文件"
                        nameFilters: ["*"]
                        selectedNameFilter: "*"
                        onAccepted: {
                            customFwText.text = fileUrl
                            close()
                            parent.forceActiveFocus()
                        }
                        onRejected: {
                            close()
                            parent.forceActiveFocus()
                        }
                    }
                }

                Page {
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        anchors.topMargin: 10

                        Rectangle {
                            Layout.fillWidth: true
                            height: 30;
                            border.width: 0
                            color: "#55" + Utility.getAppHexColor("darkAccent").slice(1)
                            border.color: "#00000000"

                            Text {
                                anchors.centerIn: parent
                                color: Utility.getAppHexColor("lightText")
                                text: "引导程序"
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        Item {
                            // Spacer
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }

                        Text {
                            color: Utility.getAppHexColor("lightText")
                            Layout.fillWidth: true
                            height: 30;
                            text: "硬件"
                            horizontalAlignment: Text.AlignHCenter
                        }

                        ComboBox {
                            id: blBox
                            Layout.preferredHeight: 48
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                            textRole: "key"
                            model: ListModel {
                                id: blItems
                            }

                            Component.onCompleted: {
                                updateBl(VescIf.getLastFwRxParams())
                            }
                        }

                        Item {
                            // Spacer
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }
                    }
                }

                Page {
                    id: pageArchive

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        anchors.topMargin: 10

                        Rectangle {
                            Layout.fillWidth: true
                            height: 30;
                            border.width: 0
                            color: "#55" + Utility.getAppHexColor("darkAccent").slice(1)
                            border.color: Utility.getAppHexColor("lightestBackground")

                            Text {
                                anchors.centerIn: parent
                                color: Utility.getAppHexColor("lightText")
                                text: "固件存档"
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        Item {
                            // Spacer
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }

                        Text {
                            color: Utility.getAppHexColor("lightText")
                            Layout.fillWidth: true
                            height: 30;
                            text: "固件版本"
                            horizontalAlignment: Text.AlignHCenter
                        }

                        ComboBox {
                            id: archVerBox
                            Layout.preferredHeight: 48
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                            popup.bottomMargin: 100

                            textRole: "key"
                            model: ListModel {
                                id: archVerItems
                            }

                            Component.onCompleted: {
                                updateArch()
                            }

                            onCurrentIndexChanged: {
                                if (archVerItems.rowCount() === 0) {
                                    return
                                }

                                archFwItems.clear()
                                var fws = fwHelper.getArchiveFirmwares(
                                            archVerItems.get(archVerBox.currentIndex).value,
                                            VescIf.getLastFwRxParams())

                                for (var name in fws) {
                                    archFwItems.append({ key: name, value: fws[name] })
                                }

                                archFwBox.currentIndex = 0
                            }
                        }

                        Text {
                            color: Utility.getAppHexColor("lightText")
                            Layout.fillWidth: true
                            height: 30;
                            text: "文件"
                            horizontalAlignment: Text.AlignHCenter
                        }

                        ComboBox {
                            id: archFwBox
                            Layout.preferredHeight: 48
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                            popup.bottomMargin: 100

                            textRole: "key"
                            model: ListModel {
                                id: archFwItems
                            }
                        }

                        Button {
                            id: archUpdateButton
                            text: "更新存档"
                            Layout.fillWidth: true

                            onClicked: {
                                dlArchiveDialog.open()
                            }
                        }

                        ProgressBar {
                            id: dlProg
                            Layout.fillWidth: true
                        }

                        Text {
                            id: dlText
                            Layout.fillWidth: true
                            color: Utility.getAppHexColor("lightText")
                        }

                        Item {
                            // Spacer
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: isHorizontal ? true : false
            Layout.preferredWidth: isHorizontal ? parent.width / 2 : parent.width
            Layout.column:0
            Layout.row: isHorizontal ? 0 : 1
            Layout.preferredHeight: asd.implicitHeight + asd.anchors.margins * 2
            color: Utility.getAppHexColor("lightBackground")

            ColumnLayout {
                id: asd
                anchors.fill: parent
                anchors.margins: 10
                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignBottom
                    color: Utility.getAppHexColor("lightText")
                    id: uploadText
                    text: "未上传"
                }

                ProgressBar {
                    id: uploadProgress
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.fillWidth: true

                    Button {
                        id: uploadButton
                        text: "上传"
                        Layout.fillWidth: true

                        onClicked: {
                            uploadFw(false)
                        }
                    }

                    Button {
                        id: uploadAllButton
                        text: "全部上传"
                        Layout.fillWidth: true
                        visible: showUploadAllButton

                        onClicked: {
                            uploadFw(true)
                        }
                    }

                    Button {
                        id: cancelButton
                        text: "取消"
                        Layout.fillWidth: true
                        enabled: false

                        onClicked: {
                            VescIf.fwUploadCancel()
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    id: versionText
                    color: Utility.getAppHexColor("lightText")
                    text:
                        "FW   : \n" +
                        "HW   : \n" +
                        "UUID : "
                    font.family: "DejaVu Sans Mono"
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    Dialog {
        id: uploadDialog
        property bool fwdCan: false
        standardButtons: Dialog.Ok | Dialog.Cancel
        width: parent.width - 20
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape

        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        Text {
            color: Utility.getAppHexColor("lightText")
            id: uploadDialogLabel
            verticalAlignment: Text.AlignVCenter
            anchors.fill: parent
            wrapMode: Text.WordWrap
        }

        onAccepted: {
            var okUploadFw = false
            if (swipeView.currentIndex == 0) {
                if (mCommands.getLimitedSupportsEraseBootloader() && blItems.count > 0) {
                    fwHelper.uploadFirmwareSingleShotTimer(fwItems.get(fwBox.currentIndex).value, VescIf, false, false,
                                                           fwdCan, blItems.get(blBox.currentIndex).value)
                } else {
                    okUploadFw = fwHelper.uploadFirmwareSingleShotTimer(fwItems.get(fwBox.currentIndex).value, VescIf, false, false, fwdCan, "")
                }
            } else if (swipeView.currentIndex == 1) {
                okUploadFw = fwHelper.uploadFirmwareSingleShotTimer(customFwText.text, VescIf, false, Qt.platform.os != "android", fwdCan,"")
            } else if (swipeView.currentIndex == 2) {
                fwHelper.uploadFirmwareSingleShotTimer(blItems.get(blBox.currentIndex).value, VescIf, true, false, fwdCan,"")
            } else if (swipeView.currentIndex == 3) {
                okUploadFw = fwHelper.uploadFirmwareSingleShotTimer(archFwItems.get(archFwBox.currentIndex).value, VescIf, false, false, fwdCan, "")
            }
        }
    }

    Dialog {
        id: dlArchiveDialog
        property bool fwdCan: false
        standardButtons: Dialog.Ok | Dialog.Cancel
        width: parent.width - 20
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape

        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        Text {
            color: Utility.getAppHexColor("lightText")
            text: "这将下载数百 MB 的旧固件，继续吗？"
            verticalAlignment: Text.AlignVCenter
            anchors.fill: parent
            wrapMode: Text.WordWrap
        }

        onAccepted: {
            archUpdateButton.enabled = false
            workaroundTimerDl.start()
        }
    }

    Timer {
        id: workaroundTimerDl
        interval: 0
        repeat: false
        running: false
        onTriggered: {
            // dlArchive...
            VescIf.downloadFwArchive()
            updateArch(VescIf.getLastFwRxParams())
            archUpdateButton.enabled = true
        }
    }

    function updateHw(params) {
        var hws = fwHelper.getHardwares(params, params.hw)

        hwItems.clear()
        fwItems.clear()

        for (var name in hws) {
            hwItems.append({ key: name, value: hws[name] })
        }

        hwBox.currentIndex = 0
        hwBox.updateFws()
    }

    function updateBl(params) {
        var bls = fwHelper.getBootloaders(params, params.hw)

        blItems.clear()

        for (var name in bls) {
            if (name.indexOf("412") !== -1) {
                blItems.insert(0, { key: name, value: bls[name] })
            } else {
                blItems.append({ key: name, value: bls[name] })
            }
        }

        blBox.currentIndex = 0
    }

    function updateArch() {
        var fws = fwHelper.getArchiveDirs()

        archVerItems.clear()
        archFwItems.clear()

        for (var name in fws) {
            archVerItems.append({ key: name, value: fws[name] })
        }

        archVerBox.currentIndex = 0
    }

    function uploadFw(fwdCan) {
        if (!VescIf.isPortConnected()) {
            VescIf.emitMessageDialog(
                        "连接错误",
                        "Not connected to device. Please connect first.",
                        false)
            return
        }

        var msg = "CAREFUL: If you continue you will lose your package and all settings, are you sure "
                  "you know what you're doing?\n\n" +
                  "这将向已连接设备上传新固件"
        var msgBl = "您即将向已连接设备上传引导程序"

        var msgEnd = "."
        if (fwdCan) {
            msgEnd = ", as well as all devices found on the CAN-bus. \n\n" +
                    "警告：仅当所有设备" +
                    "devices on the CAN-bus have the same hardware version. If that " +
                    "is not the case, you must upload firmware to the devices individually."
        }

        msg += msgEnd
        msgBl += msgEnd

        uploadDialog.fwdCan = fwdCan

        if (swipeView.currentIndex == 0) {
            if (fwItems.rowCount() === 0) {
                VescIf.emitMessageDialog(
                            "上传错误",
                            "此版本的 VESC Tool 不包含固件" +
                            "for your hardware version. You can either " +
                            "upload a custom file or look for a later version of VESC " +
                            "支持您硬件的工具。",
                            false)
                return;
            }

            if (hwItems.rowCount() === 1) {
                uploadDialog.title = "警告"

                if (VescIf.getFwSupportsConfiguration()) {
                    msg += "\n\n" +
                            "Uploading new firmware will clear all settings in the VESC firmware. You can make " +
                            "a backup of the settings from the connection page and restore them after the " +
                            "update if you'd like (if you haven't done the backup already). " +
                            "是否继续更新，还是取消并先进行备份？"
                } else {
                    msg += "\n\n" +
                            "上传新固件将清除设备上的所有设置" +
                            "and you have to do the configuration again. Do you want to " +
                            "continue?"
                }

                uploadDialogLabel.text = msg
                uploadDialog.open()
            } else {
                uploadDialog.title = "警告"
                uploadDialogLabel.text =
                        msg + "\n\n" +
                        "正在为错误的硬件版本上传固件" +
                        "将损坏硬件，请确认您已" +
                        "chosen the correct hardware version?"
                uploadDialog.open()
            }
        } else if (swipeView.currentIndex == 1) {
            if (customFwText.text.length > 0) {
                uploadDialog.title = "警告"
                uploadDialogLabel.text =
                        msg + "\n\n" +
                        "正在为错误的硬件版本上传固件" +
                        "将损坏硬件，请确认您已" +
                        "chosen the correct hardware version?"
                uploadDialog.open()
            } else {
                VescIf.emitMessageDialog(
                            "错误",
                            "Please select a file",
                            false, false)
            }
        } else if (swipeView.currentIndex == 2) {
            if (blItems.rowCount() === 0) {
                VescIf.emitMessageDialog(
                            "上传错误",
                            "此版本的 VESC Tool 不包含引导程序" +
                            "for your hardware version.",
                            false)
                return;
            }

            uploadDialog.title = "警告"

            var msgBl2 = ""
            if (!mCommands.getLimitedSupportsEraseBootloader()) {
                msgBl2 = "If the device already has a bootloader this will destroy " +
                        "the bootloader and firmware updates cannot be done anymore. "
            }

            uploadDialogLabel.text =
                    msgBl + "\n\n" + msgBl2 +
                    "是否继续？"
            uploadDialog.open()
        } else if (swipeView.currentIndex === 3) {
            if (archFwItems.rowCount() === 0) {
                VescIf.emitMessageDialog(
                            "上传错误",
                            "此版本的 VESC Tool 不包含所选固件" +
                            "for your hardware version. You can try to update the archive and see " +
                            "if it has been added since your last update.",
                            false)
                return;
            }

            uploadDialog.title = "警告"

            msg += "\n\n" +
                    "上传新固件将清除设备上的所有设置" +
                    "and you have to do the configuration again. Do you want to " +
                    "continue?"

            uploadDialogLabel.text = msg
            uploadDialog.open()
        }
    }

    Timer {
        interval: 100
        running: true
        repeat: true

        onTriggered: {
            uploadAllButton.enabled = mCommands.getLimitedSupportsFwdAllCan() &&
                    !mCommands.getSendCan() && VescIf.getFwUploadProgress() < 0

            if (!VescIf.isPortConnected()) {
                versionText.text =
                        "FW   : \n" +
                        "HW   : \n" +
                        "UUID : "
            }
        }
    }

    Connections {
        target: VescIf

        function onFwUploadStatus(status, progress, isOngoing) {
            if (isOngoing) {
                uploadText.text = status + " (" + parseFloat(progress * 100.0).toFixed(2) + " %)"
            } else {
                uploadText.text = status
            }

            uploadProgress.value = progress
            uploadButton.enabled = !isOngoing
            cancelButton.enabled = isOngoing
        }
    }

    Connections {
        target: fwHelper

        function onFwUploadRes(res, isBootloader) {
            if (res) {
                if(isBootloader) {
                    VescIf.emitMessageDialog("Bootloader Finished",
                                             "引导程序上传完成。",
                                             true, false)
                } else {
                    VescIf.disconnectPort()
                    VescIf.emitMessageDialog("警告",
                                             "The firmware upload is done. The device should reboot automatically within 10 seconds. Do " +
                                             "NOT remove power before the reboot is done as that can brick the CPU and requires a programmer " +
                                             "to fix.",
                                             true, false)
                }
            }
        }
    }

    Connections {
        target: VescIf

        function onFwRxChanged(rx, limited) {
            if (rx) {
                updateFwText()
            }
        }

        function onFwArchiveDlProgress(msg, prog) {
            dlProg.value = prog
            dlText.text = msg
            dlProgLatest.value = prog
            dlProgLatest.text = msg
        }
    }

    function updateFwText() {
        var params = VescIf.getLastFwRxParams()

        updateHw(params)

        var dlText = fwHelper.fwDlText(VescIf)
        fwIncludedText.text = dlText

        if (dlText.length > 0) {
            fwIncludedColumn.visible = false
            fwIncludedText.visible = true
        } else {
            fwIncludedText.visible = false
            fwIncludedColumn.visible = true
        }

        updateBl(params)
        updateArch()

        var testFwStr = "";
        var fwNameStr = "";

        if (params.isTestFw > 0) {
            testFwStr = " BETA " +  params.isTestFw
        }

        if (params.fwName !== "") {
            fwNameStr = " (" + params.fwName + ")"
        }

        versionText.text =
                "固件：v" + params.major + "." + (1e5 + params.minor + '').slice(-2) + fwNameStr + testFwStr + "\n" +
                "HW   : " + params.hw + "\n" +
                "UUID : " + Utility.uuid2Str(params.uuid, false)
    }
}
