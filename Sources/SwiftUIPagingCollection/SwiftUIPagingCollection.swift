// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftUI
import UIKit

struct PagingCollectionView<SetupConfig: GenericCollectionViewSetupConfig>: UIViewRepresentable {
    let itemWidth: CGFloat
    let itemHeight: CGFloat
    
    var setupConfig: SetupConfig
    var parentViewModel: SetupConfig.ViewModelType
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, setupConfig: setupConfig, parentViewModel: parentViewModel)
    }

    func makeUIView(context: Context) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        context.coordinator.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        context.coordinator.collectionView.backgroundColor = .clear
        context.coordinator.collectionView.register(SwiftUIHostingCell.self, forCellWithReuseIdentifier: "swiftUICell")
        context.coordinator.collectionView.dataSource = context.coordinator
        context.coordinator.collectionView.delegate = context.coordinator
        context.coordinator.collectionView.isPagingEnabled = true
        context.coordinator.collectionView.showsHorizontalScrollIndicator = false
        context.coordinator.collectionView.showsVerticalScrollIndicator = false
        return context.coordinator.collectionView
    }

    func updateUIView(_ uiView: UICollectionView, context: Context) {
        print("Update UIView called on Paging Collection View")
        uiView.reloadData()
    }

    class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
        var parent: PagingCollectionView
        let setupConfig: SetupConfig
        var parentViewModel: SetupConfig.ViewModelType
        var collectionView: UICollectionView!
        var previousIndex: Int?

        init(_ parent: PagingCollectionView, setupConfig: SetupConfig, parentViewModel: SetupConfig.ViewModelType) {
            self.parent = parent
            self.setupConfig = setupConfig
            self.parentViewModel = parentViewModel
        }

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return setupConfig.numberOfItems()
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "swiftUICell", for: indexPath) as? SwiftUIHostingCell else {
                fatalError("Couldn't dequeue generic SwiftUI Cell")
            }
            
            let swiftUIView = setupConfig.viewForItem(at: indexPath.row, parentViewModel: parent.parentViewModel)
            if let collectionViewVC = collectionView.findViewController() {
                cell.host(swiftUIView: swiftUIView, parent: collectionViewVC)
            }
            return cell
        }
        
        func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
            setupConfig.onScrolledToTop(parentViewModel: parentViewModel)
        }
        
        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
            let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
            if let visibleIndexPath = collectionView.indexPathForItem(at: visiblePoint) {
                previousIndex = visibleIndexPath.row
            }
        }
        
        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            // To be implemented
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
            let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
            if let visibleIndexPath = collectionView.indexPathForItem(at: visiblePoint) {
                if visibleIndexPath.row != previousIndex {
                    setupConfig.onNextItemAppeared(at: visibleIndexPath.row, parentViewModel: parentViewModel, previousIndex: previousIndex)
                }
            }
        }
    }
}

protocol GenericCollectionViewSetupConfig {
    associatedtype ItemType
    associatedtype ViewType: View
    associatedtype ViewModelType: ObservableObject
    var collectionData: [ItemType] { get set }
    func numberOfItems() -> Int
    func viewForItem(at index: Int, parentViewModel: ViewModelType) -> ViewType
    func onDraggedToNextItem(at index: Int, parentViewModel: ViewModelType)
    func onNextItemAppeared(at index: Int, parentViewModel: ViewModelType, previousIndex: Int?)
    func onScrolledToTop(parentViewModel: ViewModelType)
}

extension UIView {
    /// This traverses up the responder hierarchy to locate the next UIViewController which is necessary for properly hosting the SwiftUICell
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}

class SwiftUIHostingCell: UICollectionViewCell {
    private var hostingController: UIHostingController<AnyView>?

    func host<Content: View>(swiftUIView: Content, parent: UIViewController?) {
        hostingController?.removeFromParent()
        hostingController?.view.removeFromSuperview()

        guard let parent = parent else {
            return // If there's no parent controller, we should not proceed.
        }

        let hostingController = UIHostingController(rootView: AnyView(swiftUIView))
        parent.addChild(hostingController)
        self.contentView.addSubview(hostingController.view)
        hostingController.view.frame = self.contentView.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.didMove(toParent: parent)
        self.hostingController = hostingController
    }
}
