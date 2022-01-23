# ArtBook

<br> Core data kullanarak eklenilen seçimler yapılır ve data kaydedilir.

<p align="center">
    <img src="https://user-images.githubusercontent.com/88663603/141272758-f1857e9b-e2d0-4381-9e68-eddcb193edab.png" width="250"> 
    <img src="https://user-images.githubusercontent.com/88663603/141272690-4949f8f9-6c70-4352-b867-5201adc90f5f.png" width="250"> 
   
</p>

<a id="contribution"></a>


<br>


# toDetailsViewController.swift
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


# ViewController.swift
//
//  ViewController.swift
//  ArtBook
//
//  Created by Beytullah Özer on 26.10.2021.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
   
    @IBOutlet weak var tableView: UITableView!
    var nameArray = [String]()
    var idArray = [UUID]()
    var selectedPainting = ""
    var selectedPaintingID : UUID?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClicked))
        
        tableView.delegate = self
        tableView.dataSource = self
        
        getCoreData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getCoreData), name: NSNotification.Name(rawValue: "newData"), object: nil)
    }
    
    @objc func getCoreData () { // Verilerimizi buraya çekelim. name ve id
        
        nameArray.removeAll(keepingCapacity: false)
        idArray.removeAll(keepingCapacity: false)
        
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Paintings")
        fetchRequest.returnsObjectsAsFaults = false
        do {
            let results = try context.fetch(fetchRequest)
            for result in results as! [NSManagedObject] {
                if let name = result.value(forKey: "name") as? String {
                    self.nameArray.append(name)
                }
                if let id = result.value(forKey: "id") as? UUID {
                    self.idArray.append(id)
                }
                self.tableView.reloadData()
                
                
                
            }
        } catch {
            print("It contains error.")
        }
    }
    
    @objc func addButtonClicked () {
        performSegue(withIdentifier: "toDetailsViewController", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = nameArray[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameArray.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedPainting = nameArray[indexPath.row]
        selectedPaintingID = idArray[indexPath.row]
        performSegue(withIdentifier: "toDetailsViewController", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailsViewController" {
            let destinationVC = segue.destination as! toDetailsViewController
            destinationVC.chosenPainting = selectedPainting
            destinationVC.chosenPaintingID = selectedPaintingID
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            // Coredata'dan uygun veriyi bulup silmek
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Paintings")
            let idString = idArray[indexPath.row].uuidString
            
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString) //Aramalara koşul yazılacak onu getirecek. Görsel isim yıl artıst
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                
                let results = try context.fetch(fetchRequest)
                
                if results.count > 0 {
                    
                    for result in results as! [NSManagedObject] {
                        
                        if let id = result.value(forKey: "id") as? UUID {
                            
                            if id == idArray[indexPath.row] {
                                context.delete(result)
                                nameArray.remove(at: indexPath.row)
                                idArray.remove(at: indexPath.row)
                                self.tableView.reloadData()
                                
                                do {
                                    try context.save()
                            } catch {
                                print("Error")
                            }
                                break
                            }
                        }
                    }
                }
                
            } catch {
                print("Error")
            }
        }
    }

}



