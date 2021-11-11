//
//  toDetailsViewController.swift
//  ArtBook
//
//  Created by Beytullah Özer on 26.10.2021.
//

import UIKit
import CoreData

class toDetailsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var yearText: UITextField!
    @IBOutlet weak var artistText: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    var chosenPainting = ""
    var chosenPaintingID : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        
        if chosenPainting != "" {
            
            //saveButton.isEnabled = false //Gri az gözükür tıklanmaz
            saveButton.isHidden = true // Tamamen gözükmez
            
            // Core Data
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Paintings")
            let idString = chosenPaintingID?.uuidString
            
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString!) //Aramalara koşul yazılacak onu getirecek. Görsel isim yıl artıst
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                
                let results = try context.fetch(fetchRequest)
                
                if results.count > 0 {
                    for result in results as! [NSManagedObject]{
                        
                        if let name = result.value(forKey: "name") as? String {
                            nameText.text = name
                        }
                        if let artist = result.value(forKey: "artist") as? String {
                            artistText.text = artist
                        }
                        if let year = result.value(forKey: "year") as? Int {
                            yearText.text = String(year)
                        }
                        if let imageData = result.value(forKey: "image") as? Data {
                            let image = UIImage(data: imageData)
                            imageView.image = image
                        }
                    }
                }
            }
            catch {
                print("Error")
            }
            
            
            /* //SHOW THE CONVERT UUID TO STRING
             
            let stringConvertUUID = chosenPaintingID!.uuidString
            print(stringConvertUUID)
            //= 25E00E9F-9ECF-4BA4-881C-C660ABF7EF2C
            */
            
        }else{
            saveButton.isEnabled = true
            saveButton.isHidden = true
            
            nameText.text = ""
            artistText.text = ""
            yearText.text = ""
        }
        
        //RECOGNIZER
        
        let gestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(gestureRecognizer)
        imageView.isUserInteractionEnabled = true
        
        let tapImageGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(addImage))
        imageView.addGestureRecognizer(tapImageGestureRecognizer)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imageView.image = info[.originalImage] as? UIImage //Görseli data olarak kaydetmek amacımız
        
        saveButton.isHidden = false
        self.dismiss(animated: true, completion: nil)
        
    }
    
    @objc func hideKeyboard() {
        
        view.endEditing(true)
        
    }
    
    @objc func addImage() { //NASIL SEÇİLİP GALERİYE GÖTÜRÜLECEK.
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil) //RESİM SEÇİLDİ
        
        
    }
    
    @IBAction func saveClicked(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let newPaintings = NSEntityDescription.insertNewObject(forEntityName: "Paintings", into: context)
        
        //Attributes
        
        newPaintings.setValue(nameText.text, forKey: "name")
        newPaintings.setValue(artistText.text, forKey: "artist")
        if let year = Int(yearText.text!) {
            newPaintings.setValue(year, forKey: "year")
        }
        newPaintings.setValue(UUID(), forKey: "id")
        
        let data = imageView.image?.jpegData(compressionQuality: 0.5)
        newPaintings.setValue(data, forKey: "image")
        
        do {
            try context.save()
            print("success")
        } catch {
            print("error")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "newData"), object: nil) // ViewController arasında mesaj yazmak için kullanılır.
        self.navigationController?.popViewController(animated: true) // Storyboard üzerinde Geri gelindiğinde kaydeder ve gösterir.
      
    }
    

}
