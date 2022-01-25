import CoreGraphics
import Foundation

class Gesture {
    public static var dragStartPos = CGPoint()
    public static var currentDragDiff = CGSize()
    public static var isDragging = false

    public static func OnDragging(start: CGPoint, translation: CGSize) {
        isDragging = true
        currentDragDiff = translation
    }

    public static func OnDragEnd() {
        isDragging = false
    }
}
