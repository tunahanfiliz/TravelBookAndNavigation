//
//  ViewController.swift
//  travelBook
//
//  Created by Ios Developer on 6.10.2022.
//

import UIKit
import MapKit
import CoreLocation // kullanıcı konumu için
import CoreData

class ViewController: UIViewController, MKMapViewDelegate,CLLocationManagerDelegate {

    
    @IBOutlet weak var nameText: UITextField!
    
    @IBOutlet weak var commentText: UITextField!
    var chosenLongitude = Double()
    var chosenLatitude = Double()
    
    var selectedTitle = ""
    var selectedId : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    
    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager() // KULLANICI KONUMUNU KULLANICAKSAK.
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest// konumun verisi ne kadar keskinlikle buluncak
        locationManager.requestWhenInUseAuthorization()// kullanıcıdan izin isticez. uygulamayı kullanırken
        locationManager.startUpdatingLocation()// yeri bu ifadeyle alınmayla basşlar
        
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:))) // uzun basınca çağrılcak
        gestureRecognizer.minimumPressDuration = 3 // kaç sn basılı tutunca cıksın
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if selectedTitle != ""{
            // coredata
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            fetchRequest.returnsObjectsAsFaults = false
            
            let idString = selectedId!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            
            do{
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    
                    for result in results as! [NSManagedObject]{
                        if let title = result.value(forKey: "title") as? String {
                            annotationTitle = title
                            if let subtitle = result.value(forKey: "subtitle") as? String {
                                annotationSubtitle = subtitle
                                if let latitude = result.value(forKey: "latitude") as? Double{
                                    annotationLatitude = latitude
                                    if let longitude = result.value(forKey: "longitude") as? Double {
                                        annotationLongitude = longitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annotation) // annıtationu ekle
                                        nameText.text = annotationTitle // name teksi göster
                                        commentText.text = annotationSubtitle
                                        
                                        locationManager.stopUpdatingLocation()
                                        // alınan gğncel tıklanılan yer neresiyse oraya götürsün istiyoruz alt kısımda.
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                    }
                                }
                            }
                        }
                        
                        
                    }
                }
            }catch{
                print("error")
            }
            
            
            
            
            
        }else{// new data
            
        }
        
        
    }
    @objc func chooseLocation(gestureRecognizer:UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began{ // yukarıyı değişik yapma sebebimiz .state gibi özelliklerin çıkması için ??
            let touchedPoint = gestureRecognizer.location(in: self.mapView) // tıklanılan noktanın koordinatları için
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView) //dokunulan nokta kordinata çeviriliyor .
           
            chosenLongitude = touchedCoordinates.longitude
            chosenLatitude = touchedCoordinates.latitude
            // haritaya her tıkladıgımız noktada bu yukarıdaki kordinatlar hep değişir yani
            
            
            let annotation = MKPointAnnotation()  // pin oluşturmak
            annotation.coordinate = touchedCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text //alt baslık
            self.mapView.addAnnotation(annotation) //haritaya ekleme
            
        }
        
        
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
     
            // aşağıdaki fonksiyonları bu if içine alma sebebimiz boş degilse yani kayıtlı bir konum varsa kullanıcı yürüdükçe değiştirme diye.
        if selectedTitle == ""{
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude) // güncel bir location verir. CLLocaiton enlem ve boylam location denir.
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) // zoomlama seviyesi
            let region = MKCoordinateRegion(center: location, span: span) // CENTER yani merkezimiz location olsun
            mapView.setRegion(region, animated: true)
            // yerimizi rastgele seçmek için simulator debug location ayarları yap yukarda.
        }else{
            //
        }
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation{
            return nil // kullanıcının yerini pin ile göstermek istemiyorum tıkladıgım yeri göstermek istiyorum.
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil { // pinview daha oluşmadıysa . PİNİ ÖZELLEŞTİRMEK
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true // BALONCUKLU EKSTRA BİLGİ GÖSTEREN YER
            pinView?.tintColor = UIColor.black
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)//DETAY GÖSTEREN BUTON DEMEK
            pinView?.rightCalloutAccessoryView = button // SAĞ TARAFTA GÖSTERECEK SEKİLDE
        }else{ // PİNVİEW BOS DEGİLSE DAHA ONCE OLUŞTURULDUYSA BANA VERİLEN ANNOTATİONA EŞİTLE
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    
    // pindeki butonda tıklandıktan sonra ne olacagını gösteren fonk callout
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != "" {
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            //navigasyonu çalıstırmak için gerekli olan obje
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarks, error in //MAP ITEMİ OLUŞTURABİLMEK İÇİNDE MKPLACESMARK OLUŞTURMAK GEREKİYOR.bu mkplacemark aşağıda. BU MKPLACESMARKIDA reverseGeocodeLocation objesiyle alıyoruz.
               
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        
                        let newPlacemark = MKPlacemark(placemark: placemark[0]) // aradıgımız sey MKPlacemark ve placemark dizisinden sıfırı al
                        let item = MKMapItem(placemark: newPlacemark) //mapitem navigasyonu açmak için
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]// map itemin içinde hangi modda olacagını belirttik (Driving).
                        item.openInMaps(launchOptions: launchOptions)
                }
            }
                
            }
        }
    }
    
    @IBAction func saveButton(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        //kaydedip gösterilecek yer
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do{
            try context.save()
            print("success")
        }catch{
            print("error")
        }
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil) //newplace mesajı geldiginde napcaz aşagıda söyler
        navigationController?.popViewController(animated: true) // lisviewcontrollere geri dön demek
    }
    
    
    
}

