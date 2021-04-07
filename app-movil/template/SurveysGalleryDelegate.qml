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

import ArcGIS.AppFramework 1.0

import "SurveyHelper.js" as Helper

GalleryDelegate {
    id: galleryDelegate

    //--------------------------------------------------------------------------

    property var surveyItem: galleryView.model.get(index)

    readonly property int errorCount: surveysDatabase.statusCount(path, surveysDatabase.statusSubmitError, surveysDatabase.changed)
    readonly property int inboxCount: surveysDatabase.statusCount(path, surveysDatabase.statusInbox, surveysDatabase.changed)
    readonly property int draftsCount: surveysDatabase.statusCount(path, surveysDatabase.statusDraft, surveysDatabase.changed)
    readonly property int outboxCount: surveysDatabase.statusCount(path, surveysDatabase.statusComplete, surveysDatabase.changed)

    //--------------------------------------------------------------------------

    updateAvailable: surveyItem.updateAvailable

    //--------------------------------------------------------------------------

    Loader {
        parent: background

        anchors {
            left: indicatorsRow.layoutDirection === Qt.LeftToRight ? parent.left : undefined
            right: indicatorsRow.layoutDirection === Qt.RightToLeft ? parent.right : undefined
            bottom: parent.bottom
            margins: -5 * AppFramework.displayScaleFactor
        }

        active: debug

        sourceComponent: AccessIcon {
            access: surveyItem.access

            color: "#eeeeee"
            border {
                width: (updateAvailable ? 2 : 1) * AppFramework.displayScaleFactor
                color: updateAvailable ? "red" : "#ddd"
            }
        }
    }

    //--------------------------------------------------------------------------

    Rectangle {
        anchors {
            fill: indicatorsRow
            margins: -2 * AppFramework.displayScaleFactor
        }
        
        visible: false
        radius: height / 2
        color: "#30000000"
    }

    //--------------------------------------------------------------------------

    Row {
        id: indicatorsRow

        anchors {
            left: indicatorsRow.layoutDirection === Qt.RightToLeft ? parent.left : undefined
            right: indicatorsRow.layoutDirection === Qt.LeftToRight ? parent.right : undefined

            top: parent.top
            topMargin: 2 * AppFramework.displayScaleFactor
        }
        
        spacing: 4 * AppFramework.displayScaleFactor
        layoutDirection: localeProperties.layoutDirection
        
        CountIndicator {
            color: red
            count: errorCount
            
            onClicked: {
                indicatorsRow.indicatorClicked(0);
            }
        }
        
        CountIndicator {
            color: cyan
            count: inboxCount
            
            onClicked: {
                indicatorsRow.indicatorClicked(3);
            }
        }
        
        CountIndicator {
            color: amber
            count: draftsCount
            
            onClicked: {
                indicatorsRow.indicatorClicked(1);
            }
        }
        
        CountIndicator {
            color: green
            count: outboxCount
            
            onClicked: {
                indicatorsRow.indicatorClicked(2);
            }
        }
        /*
                CountIndicator {
                    color: blue
                    count: surveysDatabase.statusCount(path, surveysDatabase.statusSubmitted, surveysDatabase.changed)
                }
*/
        function indicatorClicked(indicator) {
            galleryView.currentIndex = index;
            if (surveyItem.survey) {
                selected(app.surveysFolder.filePath(surveyItem.survey), false, indicator, null, surveyItem);
            }
        }
    }
    
    //--------------------------------------------------------------------------

    onClicked: {
        galleryView.currentIndex = index;
        galleryView.clicked();
    }
    
    //--------------------------------------------------------------------------

    onPressAndHold: {
        galleryView.currentIndex = index;
        galleryView.pressAndHold();
    }

    //--------------------------------------------------------------------------
}
