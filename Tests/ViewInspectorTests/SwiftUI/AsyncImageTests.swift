import XCTest
import SwiftUI
@testable import ViewInspector

@available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
final class AsyncImageTests: XCTestCase {
    
    let testImage = testColor.image(CGSize(width: 100, height: 80))
    
    func testAsyncImage() throws {
        guard #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) else { return }

        let imageName = "Image"
        let url = Bundle(for: AsyncImageTests.self).url(forResource: imageName, withExtension: "png")
        let placeholder = Text("Placeholder")

        let asyncImage = AsyncImage(url: url, content: { image in
            image
        }, placeholder: {
            placeholder
        })

        try AnyView(asyncImage).inspect().anyView().asyncImage().placeholderView(Text.self)
    }
    
    func testRootImage() throws {
        let original = Image("abc")
        let wrapped = original.resizable().antialiased(true)
        XCTAssertNotEqual(original, wrapped)
        let sut = try wrapped.rootImage()
        XCTAssertEqual(sut, original)
    }
    
    func testExternalImage() throws {
        #if !os(macOS)
        let sut = Image(uiImage: testImage)
        let image = try sut.uiImage()
        #else
        let sut = Image(nsImage: testImage)
        let image = try sut.nsImage()
        #endif
        XCTAssertEqual(image, testImage)
    }
    
    func testExtractionWithModifiers() throws {
        let view = AnyView(imageView().resizable().interpolation(.low))
        #if !os(macOS)
        let image = try view.inspect().anyView().image().actualImage().uiImage()
        #else
        let image = try view.inspect().anyView().image().actualImage().nsImage()
        #endif
        XCTAssertEqual(image, testImage)
    }
    
    func testExtractionCGImage() throws {
        let cgImage = testImage.cgImage!
        let image = Image(cgImage, scale: 2.0, orientation: .down, label: Text("CGImage").bold())
        let extractedCGImage = try image.cgImage()
        let scale = try image.scale()
        let orientation = try image.orientation()
        let label = try image.inspect().image().labelView().string()
        XCTAssertEqual(extractedCGImage, cgImage)
        XCTAssertEqual(scale, 2.0)
        XCTAssertEqual(orientation, .down)
        XCTAssertEqual(label, "CGImage")
        #if !os(macOS)
        XCTAssertThrows(try image.uiImage(), "Type mismatch: CGImageProvider is not UIImage")
        #else
        XCTAssertThrows(try image.nsImage(), "Type mismatch: CGImageProvider is not NSImage")
        #endif
    }
    
    func testLabelImageText() throws {
        guard #available(iOS 14, macOS 11.0, tvOS 14.0, watchOS 7.0, *) else { return }
        let view = Label("tx", image: "img")
        let text = try view.inspect().label().icon().image().labelView()
        XCTAssertEqual(try text.string(), "img")
    }
    
    func testSearch() throws {
        let cgImage = testImage.cgImage!
        let view = AnyView(Image(cgImage, scale: 2.0, orientation: .down, label: Text("abc")).resizable())
        XCTAssertEqual(try view.inspect().find(ViewType.Image.self).pathToRoot,
                       "anyView().image()")
        XCTAssertEqual(try view.inspect().find(text: "abc").pathToRoot,
                       "anyView().image().labelView().text()")
    }
    
    func testExtractionNilCGImage() throws {
        let cgImage = unsafeBitCast(testColor.cgColor, to: CGImage.self)
        let image = Image(cgImage, scale: 2.0, orientation: .down, label: Text("CGImage"))
        XCTAssertNotNil(try image.cgImage())
    }
    
    func testExtractionFromSingleViewContainer() throws {
        let view = AnyView(imageView())
        XCTAssertNoThrow(try view.inspect().anyView().image())
    }
    
    func testExtractionFromMultipleViewContainer() throws {
        let view = HStack { imageView(); imageView() }
        XCTAssertNoThrow(try view.inspect().hStack().image(0))
        XCTAssertNoThrow(try view.inspect().hStack().image(1))
    }
    
    private func imageView() -> Image {
        #if !os(macOS)
        return Image(uiImage: testImage)
        #else
        return Image(nsImage: testImage)
        #endif
    }
}
