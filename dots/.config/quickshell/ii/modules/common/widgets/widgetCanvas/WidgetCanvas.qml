import QtQuick

Item {
    id: root

    signal clicked()

    TapHandler {
        onTapped: root.clicked()
    }
}
