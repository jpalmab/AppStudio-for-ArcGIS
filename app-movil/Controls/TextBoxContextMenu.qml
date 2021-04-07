/* Copyright 2019 Esri
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

import QtQuick 2.12
import QtQuick.Controls 2.5

import ArcGIS.AppFramework 1.0

import "Singletons"

ContextMenu {
    id: contextMenu

    //--------------------------------------------------------------------------

    property Item inputControl
    property bool restoreFocus

    //--------------------------------------------------------------------------

    width: 200 * AppFramework.displayScaleFactor

    font {
        family: inputControl.font.family
    }
    
    //--------------------------------------------------------------------------

    onAboutToShow: {
        inputControl.persistentSelection = true;
    }

    //--------------------------------------------------------------------------

    onClosed: {
        if (restoreFocus) {
            inputControl.forceActiveFocus();
        }
        inputControl.persistentSelection = false;
    }

    //--------------------------------------------------------------------------

    ContextMenuItem {
        text: qsTr("Undo")
        shortcut.sequence: StandardKey.Undo
        enabled: inputControl.canUndo
        visible: !inputControl.readOnly
        icon.source: Icons.icon("undo")
        
        onClicked: {
            inputControl.undo();
        }
    }

    ContextMenuItem {
        text: qsTr("Redo")
        shortcut.sequence: StandardKey.Redo
        enabled: inputControl.canRedo
        visible: !inputControl.readOnly
        icon.source: Icons.icon("redo")
        
        onClicked: {
            inputControl.redo();
        }
    }
    
    MenuSeparator {}
    
    ContextMenuItem {
        text: qsTr("Cut")
        shortcut.sequence: StandardKey.Cut
        enabled: inputControl.selectedText.length > 0
        visible: !inputControl.readOnly
        icon.source: Icons.icon("scissors")
        
        onClicked: {
            inputControl.cut();
        }
    }
    
    ContextMenuItem {
        text: qsTr("Copy")
        shortcut.sequence: StandardKey.Copy
        enabled: inputControl.selectedText.length > 0
        visible: !inputControl.readOnly
        icon.source: Icons.icon("copy-to-clipboard")
        
        onClicked: {
            inputControl.copy();
        }
    }
    
    ContextMenuItem {
        text: qsTr("Paste")
        shortcut.sequence: StandardKey.Paste
        enabled: inputControl.canPaste
        icon.source: Icons.icon("paste")
        
        onClicked: {
            inputControl.paste();
        }
    }
    
    MenuSeparator {}
    
    ContextMenuItem {
        text: qsTr("Select all")
        shortcut.sequence: StandardKey.SelectAll
        enabled: inputControl.length > 0
        icon.source: Icons.icon("blank")
        
        onClicked: {
            inputControl.selectAll();
        }
    }
    
    //--------------------------------------------------------------------------
}
