//
//  ProductAddViewController.swift
//  OpenFoodFacts
//
//  Created by Andrés Pizá Bückmann on 19/07/2017.
//  Copyright © 2017 Andrés Pizá Bückmann. All rights reserved.
//

import UIKit
import NotificationBanner

class ProductAddViewController: TakePictureViewController {
    // IBOutlets

    @IBOutlet weak var barcodeTitleLabel: UILabel!
    @IBOutlet weak var barcodeLabel: UILabel!
    @IBOutlet weak var topExplainationText: UILabel!
    @IBOutlet weak var licenseExplainationLabel: UILabel!

    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var productSectionTitle: UILabel!
    @IBOutlet weak var productNameTitleLabel: UILabel!
    @IBOutlet weak var productNameField: UITextField!
    @IBOutlet weak var brandsTitleLabel: UILabel!
    @IBOutlet weak var brandsField: UITextField!
    @IBOutlet weak var quantityTitleLabel: UILabel!
    @IBOutlet weak var quantityExampleLabel: UILabel!
    @IBOutlet weak var quantityField: UITextField!
    @IBOutlet weak var languageTitleLabel: UILabel!
    @IBOutlet weak var languageField: UITextField!
    @IBOutlet weak var productTextSection: UIView!

    @IBOutlet weak var nutritiveSectionTitle: UILabel!
    @IBOutlet weak var nutritivePortionSegmentedControl: UISegmentedControl!

    @IBOutlet weak var ingredientsSectionTitle: UILabel!
    @IBOutlet weak var ingredientsExplainationLabel: UILabel!
    @IBOutlet weak var ingredientsTextField: UITextView!
    @IBOutlet weak var ignoreIngredientsButton: UIButton!
    @IBOutlet weak var saveIngredientsButton: UIButton!

    @IBOutlet var saveButtons: [UIButton]!

    // Constants

    // ivars

    var activeField: UITextField?
    var contentInsetsBeforeKeyboard = UIEdgeInsets.zero
    lazy var product = Product()
    lazy var productPostErrorAlert: UIAlertController = {
        let alert = UIAlertController(title: "product-add.save-error.title".localized,
                                      message: "product-add.save-error.message".localized,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "alert.action.ok".localized,
                                      style: .default,
                                      handler: { _ in alert.dismiss(animated: true, completion: nil) }))
        return alert
    }()

    // Mandatory ivars

    override var barcode: String! {
        didSet {
            product.barcode = barcode
        }
    }

    // Private vars

    private var quantityUnitPickerController: PickerViewController?
    private var quantityUnitPickerToolbarController: PickerToolbarViewController?
    private var languagePickerController: PickerViewController?
    private var languagePickerToolbarController: PickerToolbarViewController?
    private var languageValue: String = "en" // Use English as default

    override func viewDidLoad() {
        barcodeTitleLabel.text = "product-add.titles.barcode".localized
        topExplainationText.text = "product-add.titles.top-explainations".localized
        licenseExplainationLabel.text = "product-add.titles.license-explaination".localized

        productSectionTitle.text = "product-add.titles.product-info".localized
        productNameTitleLabel.text = "product-add.label.product-name".localized
        brandsTitleLabel.text = "product-add.placeholder.brand".localized
        quantityTitleLabel.text = "product-add.label.quantity".localized
        quantityExampleLabel.text = "product-add.label.quantity-example".localized
        languageTitleLabel.text = "product-add.label.language".localized
        saveButtons.forEach { (button: UIButton) in
            button.setTitle("generic.save".localized, for: .normal)
        }

        nutritiveSectionTitle.text = "product-add.titles.nutritive".localized;
        nutritivePortionSegmentedControl.setTitle("product-add.nutritive.choice.per-hundred-grams".localized, forSegmentAt: 0)
        nutritivePortionSegmentedControl.setTitle("product-add.nutritive.choice.per-portion".localized, forSegmentAt: 1)

        ingredientsSectionTitle.text = "product-add.titles.ingredients".localized
        ingredientsExplainationLabel.text = "product-add.ingredients.explaination".localized
        ingredientsTextField.text = ""
        ignoreIngredientsButton.setTitle("product-add.ingredients.button-delete".localized, for: .normal)
        saveIngredientsButton.setTitle("product-add.ingredients.button-save".localized, for: .normal)

        configureLanguageField()
        configureDelegates()
        configureNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        barcodeLabel.text = barcode

        if let barcode = self.barcode, let pendingUploadItem = dataManager.getItemPendingUpload(forBarcode: barcode) {
            fillForm(withPendingUploadItem: pendingUploadItem)
        }
    }

    @IBAction func didTapSaveButton(_ sender: UIButton) {
        activeField?.resignFirstResponder()

        // Set field values in product
        product.name = productNameField.text
        product.lang = languageValue

        if let brand = brandsField.text {
            product.brands = [brand]
        }

        product.quantity = quantityField.text

        dataManager.addProduct(product, onSuccess: {
            self.productAddSuccessBanner.show()
            self.navigationController?.popToRootViewController(animated: true)
        }, onError: { _ in
            self.present(self.productPostErrorAlert, animated: true, completion: nil)
        })
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TakePictureSegue" {
            guard let destination = segue.destination as? PictureTableViewController else { return; }
            destination.barcode = barcode
            destination.dataManager = dataManager
        }
    }

    private func configureLanguageField() {
        let languages = dataManager.getLanguages()

        let defaultValue: Int? = languages.index(where: { $0.code == self.languageValue })

        self.languagePickerController = PickerViewController(data: languages, defaultValue: defaultValue, delegate: self)
        self.languagePickerToolbarController = PickerToolbarViewController(title: "product-add.language.toolbar-title".localized, delegate: self)

        if let pickerView = languagePickerController?.view as? UIPickerView {
            self.languageField.inputView = pickerView
        }

        if let toolbarView = languagePickerToolbarController?.view as? UIToolbar {
            self.languageField.inputAccessoryView = toolbarView
        }

        // Set current language as default
        if let languageCode = Locale.current.languageCode {
            self.languageValue = languageCode
        }

        self.languageField.text = Locale.current.localizedString(forIdentifier: self.languageValue)

        // Hide blinking cursor
        self.languageField.tintColor = .clear
    }

    private func configureDelegates() {
        productNameField.delegate = self
        brandsField.delegate = self
        quantityField.delegate = self
        languageField.delegate = self
    }

    private func configureNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }

    private func fillForm(withPendingUploadItem pendingUploadItem: PendingUploadItem) {
        if let productName = pendingUploadItem.productName {
            productNameField.text = productName
        }

        if let brand = pendingUploadItem.brand {
            brandsField.text = brand
        }

        if let quantityValue = pendingUploadItem.quantityValue {
            quantityField.text = quantityValue
        }

        // Set language
        didGetSelection(value: Language(code: pendingUploadItem.language, name: Locale.current.localizedString(forIdentifier: pendingUploadItem.language) ?? pendingUploadItem.language))
    }
}

// MARK: - Keyboard notification handler
extension ProductAddViewController {
    @objc func keyboardWillShow(notification: Notification) {
        let info = notification.userInfo
        guard let keyboardFrame = (info?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        guard let activeField = self.activeField else { return }

        let keyboardHeight: CGFloat = keyboardFrame.height < keyboardFrame.width ? keyboardFrame.height : keyboardFrame.width

        self.contentInsetsBeforeKeyboard = scrollView.contentInset
        var contentInsets = scrollView.contentInset
        contentInsets.bottom = keyboardHeight
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets

        // If field is hidden by keyboard, scroll so it's visible
        var frame = self.view.frame
        frame.size.height -= keyboardHeight
        if !frame.contains(activeField.frame.origin) {
            scrollView.scrollRectToVisible(activeField.frame, animated: true)
        }
    }

    @objc func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = self.contentInsetsBeforeKeyboard
        scrollView.scrollIndicatorInsets = self.contentInsetsBeforeKeyboard
    }
}

extension ProductAddViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeField = textField
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        activeField = nil
    }
}

extension ProductAddViewController: PickerViewDelegate {
    func didGetSelection(value: Pickable) {
        switch value {
        case let language as Language:
            self.languageValue = language.code
            self.languageField.text = language.name
        default:
            // Do nothing
            return
        }
    }

    func didDismiss() {
        self.activeField?.resignFirstResponder()
    }
}
