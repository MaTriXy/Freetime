//
//  SettingsAddAccountSectionController.swift
//  Freetime
//
//  Created by Ryan Nystrom on 5/17/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import IGListKit

final class SettingsAddAccountSectionController: ListSectionController {

    let rootNavigationManager: RootNavigationManager

    init(rootNavigationManager: RootNavigationManager) {
        self.rootNavigationManager = rootNavigationManager
        super.init()
    }

    override func sizeForItem(at index: Int) -> CGSize {
        guard let context = collectionContext else { fatalError("Collection context must be set") }
        return CGSize(width: context.containerSize.width, height: Styles.Sizes.tableCellHeight)
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard let cell = collectionContext?.dequeueReusableCell(of: ButtonCell.self, for: self, at: index) as? ButtonCell
            else { fatalError("Collection context must be set or cell incorrect type") }
        cell.label.text = NSLocalizedString("Add another account", comment: "")
        cell.label.textColor = Styles.Colors.Blue.medium.color
        cell.configure(topSeparatorHidden: false, bottomSeparatorHidden: false)
        return cell
    }

    override func didSelectItem(at index: Int) {
        guard let nav = viewController?.navigationController else { return }
        rootNavigationManager.pushLoginViewController(nav: nav)
    }

}

