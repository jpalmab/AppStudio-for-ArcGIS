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

import QtQuick 2.11

ListModel {
    property bool useArraySort

    property string sortProperty
    property var sortFunction

    property int sortType: kSortTypeProperty
    property string sortOrder: kSortOrderAsc
    property int sortCaseSensitivity: Qt.CaseInsensitive

    property var sortProperties
    property var sortOrders

    readonly property int kSortTypeProperty: 0
    readonly property int kSortTypeFunction: 1

    readonly property string kSortOrderAsc: "asc"
    readonly property string kSortOrderDesc: "desc"

    property bool debug: false

    //--------------------------------------------------------------------------

    dynamicRoles: true

    //--------------------------------------------------------------------------

    function sort(begin, end) {
        if (sortType === kSortTypeProperty) {
            if (!(sortProperty > "")) {
                console.error("Empty sortProperty");
                return;
            }
        } else {
            if (typeof sortFunction !== 'function') {
                console.error("Invalid sort function:", sortFunction);
                return;
            }
        }

        if (begin === undefined) {
            begin = 0;
        }

        if (end === undefined) {
            end = count;
        }

        if (debug) {
            console.log("Sorting:", begin, "to:", end, "property:", sortProperty, sortOrder);
        }

        if (useArraySort) {
            arraySort(begin, end);
        } else {
            qsort(begin, end);
        }
    }

    //--------------------------------------------------------------------------

    function arraySort(begin, end) {
        if (begin < 0 || end > count || begin === end) {
            console.error("Invalid sort parameter", begin, end, count);
            return;
        }

        var array = [];
        for (var i = begin; i < end; i++) {
            array.push(get(i))
        }

        array.sort(sortType === kSortTypeProperty ? propertySort : sortFunction);

        for (i = 0; i < end - begin; i++) {
            insert(end + i, array[i]);
        }
        remove(begin, end - begin);
    }

    //--------------------------------------------------------------------------

    // This is slower than arraySort() and crashes on iOS for large datasets (#1939)
    function qsort(begin, end) {
        if (end - 1 > begin) {
            var pivot = begin + Math.floor(Math.random() * (end - begin));

            switch (sortType) {
            case kSortTypeProperty:
                pivot = partition_property(begin, end, pivot);
                break;

            case kSortTypeFunction:
                if (typeof sortFunction !== 'function') {
                    console.error("Invalid sort function:", sortFunction);
                    return;
                }

                pivot = partition_function(begin, end, pivot);
                break;

            default:
                console.error("Invalid sort type:", sortType);
                return;
            }

            qsort(begin, pivot);
            qsort(pivot + 1, end);
        }
    }

    //--------------------------------------------------------------------------

    function partition_property(begin, end, pivot) {
        var pivotValue = get(pivot)[sortProperty];
        if (sortCaseSensitivity === Qt.CaseInsensitive) {
            pivotValue = toCaseInsensitive(pivotValue);
        }

        swap(pivot, end - 1);
        var store = begin;

        for (var index = begin; index < end - 1; index++) {
            var indexValue = get(index)[sortProperty];
            if (sortCaseSensitivity === Qt.CaseInsensitive) {
                indexValue = toCaseInsensitive(indexValue);
            }

            if (sortOrder === kSortOrderAsc && indexValue < pivotValue) {
                swap(store, index);
                store++;
            } else if (sortOrder === kSortOrderDesc && indexValue > pivotValue) {
                swap(store, index);
                store++;
            }
        }

        swap(end - 1, store);

        return store;
    }

    //--------------------------------------------------------------------------

    function partition_function(begin, end, pivot) {
        var pivotItem = get(pivot);

        swap(pivot, end - 1);
        var store = begin;

        for (var index = begin; index < end - 1; index++) {
            var indexItem = get(index);

            var v = sortFunction(indexItem, pivotItem);
            if (sortOrder === kSortOrderAsc && v < 0) {
                swap(store, index);
                store++;
            } else if (sortOrder === kSortOrderDesc && v > 0) {
                swap(store, index);
                store++;
            }
        }

        swap(end - 1, store);

        return store;
    }

    //--------------------------------------------------------------------------

    function swap(a, b) {
        if (a < b) {
            move(a, b, 1);
            move(b - 1, a, 1);
        }
        else if (a > b) {
            move(b, a, 1);
            move(a - 1, b, 1);
        }
    }

    //--------------------------------------------------------------------------

    function toCaseInsensitive(value) {
        if (!value) {
            return value;
        }

        if (typeof value !== "string") {
            return value;
        }

        return value.toString().toLocaleLowerCase();
    }

    //--------------------------------------------------------------------------

    function toggleSortOrder() {
        sortOrder = sortOrder === kSortOrderAsc ? kSortOrderDesc : kSortOrderAsc;

        if (debug) {
            console.log("Toggled sort order:", sortProperty, sortOrder);
        }
    }

    //--------------------------------------------------------------------------

    function findByKeyValue(key, value) {
        for (var i = 0; i < count; i++) {
            if (get(i)[key] === value) {
                return i;
            }
        }

        return -1;
    }

    //--------------------------------------------------------------------------

    function propertySort(item1, item2) {
        var sortFactor = sortOrder === kSortOrderDesc ? -1 : 1;

        var value1 = sortCaseSensitivity === Qt.CaseInsensitive
                ? toCaseInsensitive(item1[sortProperty])
                : item1[sortProperty];

        var value2 = sortCaseSensitivity === Qt.CaseInsensitive
                ? toCaseInsensitive(item2[sortProperty])
                : item2[sortProperty];

        return (value1 < value2) ? -1 * sortFactor : (value1 > value2) ? 1 * sortFactor : 0;
    }

    //--------------------------------------------------------------------------

    function propertiesSort(item1, item2) {

        for (var i = 0; i < sortProperties.length; i++) {
            var sortProperty = sortProperties[i];

            var value1 = sortCaseSensitivity === Qt.CaseInsensitive
                    ? toCaseInsensitive(item1[sortProperty])
                    : item1[sortProperty];

            var value2 = sortCaseSensitivity === Qt.CaseInsensitive
                    ? toCaseInsensitive(item2[sortProperty])
                    : item2[sortProperty];

            var sortFactor = (Array.isArray(sortOrder) ? sortOrder[i] : sortOrder) === kSortOrderDesc ? -1 : 1;

            if (value1 < value2) {
                return -1 * sortFactor;
            } else if (value1 > value2) {
                return 1 * sortFactor;
            }
        }

        return 0;
    }

    //--------------------------------------------------------------------------
}
