import SwiftUI

@available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
public extension ViewType {

    struct AsyncImage: KnownViewType {
        public static let typePrefix: String = "AsyncImage"
    }
}

// MARK: - Extraction from SingleViewContent parent

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
public extension InspectableView where View: SingleViewContent {

    func asyncImage() throws -> InspectableView<ViewType.AsyncImage> {
        return try .init(try child(), parent: self)
    }
}

// MARK: - Extraction from MultipleViewContent parent

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
public extension InspectableView where View: MultipleViewContent {

    func asyncImage(_ index: Int) throws -> InspectableView<ViewType.AsyncImage> {
        return try .init(try child(at: index), parent: self, index: index)
    }
}

// MARK: - Non Standard Children

@available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
extension ViewType.AsyncImage: SupplementaryChildren {
    static func supplementaryChildren(_ parent: UnwrappedView) throws -> LazyGroup<SupplementaryView> {
        return .init(count: 1) { index in
            let image = try Inspector.cast(value: parent.content.view, type: Image.self)
                .rootImage()
            let labelView: Any = try {
                if let view = try? Inspector.attribute(path: "provider|base|label|some|text", value: image) {
                    return view
                }
                return try Inspector.attribute(path: "provider|base|label", value: image)
            }()
            let medium = parent.content.medium.resettingViewModifiers()
            let content = try Inspector.unwrap(content: Content(labelView, medium: medium))
            return try InspectableView<ViewType.ClassifiedView>(
                content, parent: parent, call: "labelView()")
        }
    }
}

// MARK: - Custom Attributes

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
public extension InspectableView where View == ViewType.AsyncImage {

    func contentView<V>(_ type: V.Type = V.self) throws -> V {
        return try Inspector.cast(value: content.view, type: V.self)
    }

    func placeholderView<P>(_ type: P.Type = P.self) throws -> P {
        return try Inspector.cast(value: View.supplementaryChildren(self).element(at: 0), type: P.self)
    }
}

// MARK: - AsyncImage

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
public extension SwiftUI.AsyncImage {

    func rootImage() throws -> AsyncImage<Content> {
        return try Inspector.cast(value: imageContent().view, type: AsyncImage<Content>.self)
    }

    func url() throws -> URL? {
        return try Inspector
            .attribute(label: "url", value: rawAsyncImage(), type: URL.self)
    }

    func scale() throws -> CGFloat {
        return try Inspector
            .attribute(label: "scale", value: rawAsyncImage(), type: CGFloat.self)
    }

    func transaction() throws -> Transaction {
        return try Inspector
            .attribute(label: "transaction", value: rawAsyncImage(), type: Transaction.self)
    }

    private func rawAsyncImage() throws -> Any {
        return try Inspector.attribute(path: "provider|base", value: try imageContent().view)
    }

    private func imageContent() throws -> ViewInspector.Content {
        return try Inspector.unwrap(image: self)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension Inspector {
    static func unwrap<V>(image: AsyncImage<V>) throws -> Content where V: View {
        let provider = try Inspector.attribute(path: "provider|base", value: image)
        if let child = try? Inspector.attribute(label: "base", value: provider, type: AsyncImage<V>.self) {
            let content = try unwrap(image: child)
            let medium = content.medium.appending(viewModifier: provider)
            return Content(content.view, medium: medium)
        }
        return Content(image)
    }
}

