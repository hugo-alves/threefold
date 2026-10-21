import XCTest

final class SessionSwipeUITests: XCTestCase {
    private func capture(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func expectTitle(_ title: String, app: XCUIApplication) {
        let element = app.staticTexts["conversationTitle"]
        XCTAssertTrue(element.waitForExistence(timeout: 8))
        let expected = NSPredicate(format: "label == %@", title)
        expectation(for: expected, evaluatedWith: element)
        waitForExpectations(timeout: 8)
    }

    private func history(_ title: String, app: XCUIApplication) {
        app.buttons["conversationOptions"].tap()
        let item = app.buttons[title]
        XCTAssertTrue(item.waitForExistence(timeout: 5))
        item.tap()
    }

    private func reveal(_ element: XCUIElement, app: XCUIApplication) {
        let table = app.tables["gestureSettings"]
        for _ in 0..<12 {
            if element.exists && element.isHittable { return }
            table.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }

    func testDraftReadingPositionAndTuningSurviveSwitchingAndReopening() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-test-state"]
        app.launch()
        expectTitle("Explore alternative approaches", app: app)
        let dismissHint = app.buttons["Dismiss gesture hint"]
        XCTAssertTrue(dismissHint.waitForExistence(timeout: 5))
        capture("01-first-use", app: app)
        dismissHint.tap()

        app.staticTexts["conversationTitle"].press(forDuration: 0.8)
        let speed = app.sliders["animationSpeed"]
        reveal(speed, app: app)
        speed.adjust(toNormalizedSliderPosition: 0.65)
        let distance = app.sliders["swipeDistance"]
        reveal(distance, app: app)
        XCTAssertTrue(distance.waitForExistence(timeout: 5))
        distance.adjust(toNormalizedSliderPosition: 0.2)
        let savedDistance = distance.value as? String
        let sensitivity = app.sliders["flickSensitivity"]
        reveal(sensitivity, app: app)
        sensitivity.adjust(toNormalizedSliderPosition: 0.7)
        let haptics = app.segmentedControls["haptics"]
        reveal(haptics, app: app)
        haptics.buttons["Off"].tap()
        capture("02-gesture-settings", app: app)
        app.navigationBars.buttons["Done"].tap()

        let field = app.textFields["composer"]
        field.tap()
        field.typeText(" Keep this unfinished thought ")
        let draft = field.value as? String
        XCTAssertTrue(draft?.contains("Keep this unfinished thought") == true)

        // Switching with the keyboard open exercises the same transition used by the gesture.
        history("Previous session", app: app)
        expectTitle("Prototype swipe session switching", app: app)
        capture("03-code-conversation", app: app)
        history("Next session", app: app)
        expectTitle("Explore alternative approaches", app: app)
        XCTAssertEqual(field.value as? String, draft)
        XCTAssertFalse(app.keyboards.firstMatch.exists)

        let scroll = app.scrollViews["conversationScroll"]
        scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4))
            .press(forDuration: 0.1, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6)))
        let anchor = app.textViews.matching(NSPredicate(format: "value == %@", "One document. One clearer next step.")).firstMatch
        XCTAssertTrue(anchor.exists)
        let readingY = anchor.frame.minY
        capture("04-reading-position", app: app)

        history("Previous session", app: app)
        expectTitle("Prototype swipe session switching", app: app)
        history("Next session", app: app)
        expectTitle("Explore alternative approaches", app: app)
        XCTAssertEqual(anchor.frame.minY, readingY, accuracy: 3)

        XCUIDevice.shared.press(.home)
        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        expectTitle("Explore alternative approaches", app: app)
        XCTAssertEqual(field.value as? String, draft)
        XCTAssertEqual(anchor.frame.minY, readingY, accuracy: 3)
        XCTAssertFalse(dismissHint.exists)
        capture("05-restored-conversation", app: app)

        // Compare with ordinary list navigation; the conversation keeps the same state.
        app.buttons["Back to sessions"].tap()
        app.cells["session-swipe"].tap()
        expectTitle("Prototype swipe session switching", app: app)
        app.buttons["Back to sessions"].tap()
        app.cells["session-approaches"].tap()
        expectTitle("Explore alternative approaches", app: app)
        XCTAssertEqual(field.value as? String, draft)
        XCTAssertEqual(anchor.frame.minY, readingY, accuracy: 3)

        app.staticTexts["conversationTitle"].press(forDuration: 0.8)
        reveal(distance, app: app)
        XCTAssertTrue(distance.waitForExistence(timeout: 5))
        XCTAssertEqual(distance.value as? String, savedDistance)
        reveal(haptics, app: app)
        XCTAssertTrue(app.segmentedControls["haptics"].buttons["Off"].isSelected)
        app.navigationBars.buttons["Done"].tap()
    }
}
