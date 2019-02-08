//
//  PictureTableViewController.swift
//  OpenFoodFacts
//
//  Created by Andrés Pizá Bückmann on 02/10/2017.
//  Copyright © 2017 Andrés Pizá Bückmann. All rights reserved.
//

import UIKit

protocol PictureTableViewControllerDelegate: class {
    func didPostIngredientImage()
}

class PictureTableViewController: TakePictureViewController {
    @IBOutlet weak var tableView: UITableView!
    var pictures: [PictureViewModel]!
    weak var delegate: PictureTableViewControllerDelegate?

    override func viewDidLoad() {
        tableView.isScrollEnabled = false
        pictures = [PictureViewModel]()
        pictures.append(PictureViewModel(imageType: .front))
        pictures.append(PictureViewModel(imageType: .ingredients))
        pictures.append(PictureViewModel(imageType: .nutrition))
    }

    @IBAction func didTapCellTakePictureButton(_ sender: UIButton) {
        guard let cell = sender.superview?.superview?.superview?.superview as? PictureTableViewCell else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        imageType = pictures[indexPath.row].imageType
        didTapTakePictureButton(sender)
    }

    override func postImageSuccess(image: UIImage, forImageType imageType: ImageType) {
        guard let pictureIndex = pictures.firstIndex(where: { (pic: PictureViewModel) -> Bool in
            return pic.imageType == imageType
        }) else { return }
        log.debug("### got image for \(imageType)")
        pictures[pictureIndex].image = image
        tableView.reloadRows(at: [IndexPath(row: pictureIndex, section: 0)], with: .automatic)

        if imageType == .ingredients {
            delegate?.didPostIngredientImage()
        }
    }
}

// MARK: - UITableViewDataSource
extension PictureTableViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pictures.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PictureTableViewCell.self)) as? PictureTableViewCell else {
            fatalError("The cell is missing. No cell, no table.")
        }
        cell.configure(viewModel: pictures[indexPath.row])
        return cell
    }
}
