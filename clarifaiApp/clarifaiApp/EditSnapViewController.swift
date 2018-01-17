//
//  EditSnapViewController.swift
//  clarifaiApp
//
//  Created by Erin Abrams on 17/1/18.
//  Copyright © 2018 partywolfAPPS. All rights reserved.
//

import UIKit
import Clarifai
import SnapKit
import Foundation
import AVFoundation

class EditSnapViewController: UIViewController, UIImagePickerControllerDelegate,
UINavigationControllerDelegate {
    
    // Declaring Variables - Globals
    var app:ClarifaiApp?
    let picker = UIImagePickerController()
    var poems = [String]()
    var loaded = false
    var tagOne = "no poem"
    var newImage: UIImage!

    
    // Photo options
    @IBOutlet weak var backNavButton: UIButton!
    @IBOutlet weak var shareNavButton: UIButton!
    @IBOutlet weak var savePhoto: UIButton!
    @IBOutlet weak var fontStyle: UIButton!
    @IBOutlet weak var textColour: UIButton!
    @IBOutlet weak var poeticText: UITextView!
    @IBOutlet weak var photoTaken: UIImageView!
    
    // edit poem text options
    @IBOutlet weak var colourBlack: UIButton!
    @IBOutlet weak var colourWhite: UIButton!
    @IBOutlet weak var colourBlue: UIButton!
    @IBOutlet weak var colourYellow: UIButton!
    @IBOutlet weak var colourRed: UIButton!
    @IBOutlet weak var colourGreen: UIButton!
    @IBOutlet weak var colourOrange: UIButton!
    @IBOutlet weak var colourPurple: UIButton!
    
    var whiteImage = UIImage(named: "White")!
    var blackImage = UIImage(named: "Black")!
    var blueImage = UIImage(named: "Blue")!
    var purpleImage = UIImage(named: "Purple")!
    var greenImage = UIImage(named: "Green")!
    var yellowImage = UIImage(named: "Yellow")!
    var orangeImage = UIImage(named: "Orange")!
    var redImage = UIImage(named: "Red")!
    
    @IBOutlet weak var changeColourView: UIView!
    @IBOutlet weak var changeFontView: UIView!

    override func viewDidLoad() {
        
        photoTaken.image = newImage
        changeColourView.isHidden = true
        
        setupPhotoUI()
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //Declare my api key
        app = ClarifaiApp(apiKey: "ab5e1c0750f14e5685e24b243de99d27")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // Recognize the Image with Clarifai
    func recognizeImage(image: UIImage) {
        
        // Check that the application was initialized correctly.
        if let app = app {
            
            // Fetch Clarifai's general model.
            app.getModelByName("general-v1.3", completion: { (model, error) in
                
                // Create a Clarifai image from a uiimage.
                let caiImage = ClarifaiImage(image: image)!
                
                // Use Clarifai's general model to pedict tags for the given image.
                model?.predict(on: [caiImage], completion: { (outputs, error) in
                    print("%@", error ?? "no error")
                    guard
                        let caiOuputs = outputs
                        else {
                            print("Predict failed")
                            return
                    }
                    
                    if let caiOutput = caiOuputs.first {
                        // Loop through predicted concepts (tags), and display them on the screen.
                        let tags = NSMutableArray()
                        for concept in caiOutput.concepts {
                            
                            // Removes the tag "no person" as it was causing problems
                            if ( concept.conceptName! == "no person" ){
                                tags.remove(concept.conceptName)
                            } else {
                                tags.add("It is \(concept.conceptName!)")
                                
                                
                            }
                            
                        }
                        
                        // Wait for the API to load before outputing to screen
                        DispatchQueue.main.async {
                            // Update the new tags in the UI.
                            //self.textView.text = String(format: "Tags: ", tags.componentsJoined(by: " "))
                            
                            
                            // Take all the tags and push them into a string
                            
                            self.tagOne = "\(tags)"
                            
                            print(tags)
                            // Send tag to our API to generate poetry
                            //self.getRequest(poemName: self.tagOne)
                            
                            //Check if list of tags contains one of our key topics, to generate relevant poem
                            if (self.tagOne.contains("animal")){
                                print("Poem topic identified as Animals")
                                self.generateAnimal1()
                            }
                            else if (self.tagOne.contains("nature")){
                                print("Poem topic identified as Nature")
                                self.generateNature1()
                            }
                            else if (self.tagOne.contains("people")){
                                print("Poem topic identified as People")
                                self.generatePeople1()
                            }
                            else {
                                print("Poem topic not identified")
                                self.generatePoem2()
                            }
                            
                        }
                        
                    }
                    
                    // Once finished enable buttons again
                    DispatchQueue.main.async {
                        
                        
                        
                    }
                    
                })
            })
        }
        
    }
    
    //identify word class for each word in sentence
    func getWordClass(text: String, language: String = "en")->[String:[String]]{
        
        // Disregards the unimportant things inside the text ie. gaps, puncuation etc..
        let options: NSLinguisticTagger.Options = [.omitWhitespace, .omitPunctuation, .joinNames]
        // Chooses a language english
        let schemes = NSLinguisticTagger.availableTagSchemes(forLanguage: language)
        // Tags will be english and the options will be disregarded.
        let tagger = NSLinguisticTagger(tagSchemes: schemes, options: Int(options.rawValue))
        
        var words = [String:[String]]()
        
        // Text perameter becomes a tagger string
        tagger.string = text
        // Text is then converted to NSString
        let tmpString = text as NSString
        // The range is the max length of tmpString
        let range = NSRange(location: 0, length: tmpString.length)
        
        // The tagger beginners classing the words inside the tmpString with Noun, Verb, Adj etc
        tagger.enumerateTags(in: range, scheme: NSLinguisticTagSchemeNameTypeOrLexicalClass, options: options) { (tag, tokenRange, _, _) in
            
            let token = tmpString.substring(with: tokenRange)
            
            if(words[tag] == nil){
                words[tag] = [String]()
            }
            
            words[tag]!.append(token)
            
        }
        
        return words
    }
    
    
    //if there aren't enough  adj/verb/adverb in image tags for us to choose from, we can use those supplement
    let wordSupplement = ["Adjective":["sweet", "beautiful", "bright", "shining", "brilliant", "wonderful", "gigantic", "huge", "little", "amazing", "great", "shy", "lazy", "exciting", "slow", "smooth", "soft", "warm"], "Verb":["run", "walk", "jump", "fly", "laugh", "smile", "sing", "rise", "cry", "swim", "climb", "burn", "eat", "push", "sit", "look"], "Adverb":["happily", "excitedly", "cheerfully", "lightly", "alone", "fast", "gladly", "swiftly", "shyly", "brightly", "silently", "lazily", "excitingly", "slowly", "smoothly", "softly", "warmly"], "Pronoun":["he","she","they"], "Detirminer":["the", "every", "this", "those", "that", "many", "my", "his", "hers", "yours"]]
    
    //select a specific type of word from the image tags
    func selectRandomWord(wordClass:String, imageTags:[String:[String]])->String{
        
        if(imageTags[wordClass] == nil){
            let len = wordSupplement[wordClass]!.count
            let random = Int(arc4random_uniform(UInt32(len)))
            
            return wordSupplement[wordClass]![random]
        }
        else{
            let len = imageTags[wordClass]!.count
            let random = Int(arc4random_uniform(UInt32(len)))
            
            return imageTags[wordClass]![random]
        }
    }
    
    //define article(a/an) before word
    func getArticle(word: String)->String{
        var firstCharacter = ""
        firstCharacter.append(word[word.startIndex])
        let vowels = ["a", "e", "i", "o", "u"]
        
        for i in 0..<vowels.count{
            if(firstCharacter.lowercased() == vowels[i]){
                return "an"
            }
        }
        
        return "a"
    }
    
    
    
    //    for (wordClass, wordArray) in words{
    //    print("\(wordClass): \(wordArray)")
    //    }
    
    /*poem structure 1
     I am in the {0:noun}, it is so {1:adj}
     What a/an {2:adj} {3:noun}
     I cannot erase this {4:noun} in my mind
     Just {5: adv} {6:verb}ing
     */
    
    func generatePoem1()->String{
        //image tags
        print(tagOne)
        let words = getWordClass(text: tagOne, language: "en")
        print(words)
        
        let wordClasses = ["Noun", "Adjective", "Adjective", "Noun", "Noun", "Adverb", "Verb"]
        var chosenWords = [String]()
        for i in 0..<wordClasses.count{
            chosenWords.append(selectRandomWord(wordClass: wordClasses[i], imageTags: words))
        }
        var poem = "I am in the " + chosenWords[0] + ", it is so " + chosenWords[1] + ".\n"
        poem += "What " + getArticle(word: chosenWords[2]) + " " + chosenWords[2] + " " + chosenWords[3]
        poem += "\nI cannot erase that " + chosenWords[4] + " in my mind\n"
        poem += "Just " + chosenWords[5] + " " + chosenWords[6] + "ing"
        
        
        // Output to text view element
        self.poeticText.text = "\(poem)"
        print("\(poem)")
        return poem
    }
    
    /*poem structure 2
     The {0:noun} {1:verb} in the {2:noun}
     Without {3:determiner} {4:adjective} or {5:adjective}
     {6:Pronoun} {7:adverb} the {8:noun}"
     */
    
    func generatePoem2()->String{
        //image tags
        print(tagOne)
        let words = getWordClass(text: tagOne, language: "en")
        print(words)
        /*print poem structure*/
        print("Poem Structure:\n")
        
        print("The {noun} {verb} in the {noun}\nWithout {determiner} {adjective} or {adjective}\n{Pronoun} {adverb} the {noun}")
        print("Poem:\n")
        
        let wordClasses = ["Noun", "Verb", "Noun", "Detirminer", "Adjective", "Adjective", "Pronoun", "Verb", "Noun",]
        var chosenWords = [String]()
        for i in 0..<wordClasses.count{
            chosenWords.append(selectRandomWord(wordClass: wordClasses[i], imageTags: words))
        }
        var poem = "The " + chosenWords[0] + " " + chosenWords[1] + " in the " + chosenWords[2]
        poem += ".\n Without " + chosenWords[3] + " " + chosenWords[4] + " or " + chosenWords[5] + ".\n"
        poem += chosenWords[6] + " " + chosenWords[7] + " the " + chosenWords[8]
        
        
        
        // Output to text view element
        self.poeticText.text = "\(poem)"
        
        return poem
    }
    
    
    /*
     Animal poem structure #1
     {0:adj} {1:noun}, with your eyes so {2:adj}
     You see the {3:noun} so {4:adj} and {5:adj}
     Time to {6:verb}, so much to {7:verb}
     */
    
    func generateAnimal1()->String{
        //image tags
        print(tagOne)
        let words = getWordClass(text: tagOne, language: "en")
        
        print(words)
        
        let wordClasses = ["Adjective", "Noun", "Adjective", "Noun", "Adjective", "Adjective", "Verb", "Verb"]
        var chosenWords = [String]()
        for i in 0..<wordClasses.count{
            chosenWords.append(selectRandomWord(wordClass: wordClasses[i], imageTags: words))
        }
        var poem =  getArticle(word: chosenWords[0]) + " " + chosenWords[0] + " " + chosenWords[1] + ", with your eyes so " + chosenWords[2] + ", \n"
        poem += "You see the " + chosenWords[3] + " so " + chosenWords[4] + " and " + chosenWords[5] + ", \n"
        poem += "Time to " + chosenWords[6] + ", so much to " + chosenWords[7] + "."
        
        print(getArticle(word: chosenWords[0]))
        print(chosenWords[0])
        print(chosenWords[1])
        // Output to text view element
        self.poeticText.text = "\(poem)"
        print("\(poem)")
        return poem
    }
    
    /*
     Animal poem structure #2
     I have a {0:adj} {1:noun}
     Most {2: adj} for miles around
     Wherever there’s lots of {3:noun}
     That’s where he’ll {4:verb}
     
     */
    func generateAnimal2()->String{
        //image tags
        print(tagOne)
        let words = getWordClass(text: tagOne, language: "en")
        print(words)
        
        let wordClasses = ["Noun", "Adjective", "Adjective", "Noun", "Noun", "Adverb", "Verb"]
        var chosenWords = [String]()
        for i in 0..<wordClasses.count{
            chosenWords.append(selectRandomWord(wordClass: wordClasses[i], imageTags: words))
        }
        var poem = "I am in the " + chosenWords[0] + ", it is so " + chosenWords[1] + ".\n"
        poem += "What " + getArticle(word: chosenWords[2]) + " " + chosenWords[2] + " " + chosenWords[3]
        poem += "\nI cannot erase that " + chosenWords[4] + " in my mind\n"
        poem += "Just " + chosenWords[5] + " " + chosenWords[6] + "ing"
        
        
        // Output to text view element
        self.poeticText.text = "\(poem)"
        print("\(poem)")
        return poem
    }
    
    /*
     Nature poem structure #1
     Let your eyes consume the beauty of {0:noun}
     Let {1: adj} {2:noun} soothe your mind
     You’ll feel the aloha spirit—
     A more {3:adj} {4:noun} you won’t find
     
     */
    func generateNature1()->String{
        //image tags
        print(tagOne)
        let words = getWordClass(text: tagOne, language: "en")
        print(words)
        
        let wordClasses = ["Noun", "Adjective", "Adjective", "Noun", "Noun", "Adverb", "Verb"]
        var chosenWords = [String]()
        for i in 0..<wordClasses.count{
            chosenWords.append(selectRandomWord(wordClass: wordClasses[i], imageTags: words))
        }
        var poem = "I am in the " + chosenWords[0] + ", it is so " + chosenWords[1] + ".\n"
        poem += "What " + getArticle(word: chosenWords[2]) + " " + chosenWords[2] + " " + chosenWords[3]
        poem += "\nI cannot erase that " + chosenWords[4] + " in my mind\n"
        poem += "Just " + chosenWords[5] + " " + chosenWords[6] + "ing"
        
        
        // Output to text view element
        self.poeticText.text = "\(poem)"
        print("\(poem)")
        return poem
    }
    
    
    /*
     Nature poem structure #2
     {0:noun} is such a {1:adj} sight,
     With {2:adj} {3:noun} and {4:adj} {5:noun}
     An abundance of {6:noun}, what pure delight
     */
    
    func generateNature2()->String{
        //image tags
        print(tagOne)
        let words = getWordClass(text: tagOne, language: "en")
        print(words)
        
        let wordClasses = ["Noun", "Adjective", "Adjective", "Noun", "Adjective", "Noun", "Noun"]
        var chosenWords = [String]()
        for i in 0..<wordClasses.count{
            chosenWords.append(selectRandomWord(wordClass: wordClasses[i], imageTags: words))
        }
        var poem = chosenWords[0] + " is such a " + chosenWords[1] + " sight,"
        poem += "\nWith " + chosenWords[2] + " " + chosenWords[3] + " and " + chosenWords[4] + " " + chosenWords[5]
        poem += "\nWith " + chosenWords[6] + " in my mind"
        poem += "\nAn abundance of " + chosenWords[7] + " what pure delight."
        
        
        // Output to text view element
        self.poeticText.text = "\(poem)"
        print("\(poem)")
        return poem
    }
    
    /*
     Room poem structure #1
     A {0:adj} {1:noun}
     A {2:adj} {3:adj} room
     With {4:noun} and {5:noun} tossed throughout
     Where does that {6:adj} {7:noun} come from ?
     */
    
    func generateRoom1()->String{
        //image tags
        print(tagOne)
        let words = getWordClass(text: tagOne, language: "en")
        print(words)
        
        let wordClasses = ["Adjective", "Noun", "Adjective", "Adjective", "Noun", "Noun", "Adjective", "Noun"]
        var chosenWords = [String]()
        for i in 0..<wordClasses.count{
            chosenWords.append(selectRandomWord(wordClass: wordClasses[i], imageTags: words))
        }
        var poem = "A " + chosenWords[0] + " " + chosenWords[1]
        poem += "\n" + chosenWords[2] + " " + chosenWords[3] + " room "
        poem += "\nWith " + chosenWords[4] + " and " + chosenWords[5] + " tossed throughout"
        poem += "\nWhere does that " + chosenWords[6] + " " + chosenWords[7] + " come from?"
        
        
        // Output to text view element
        self.poeticText.text = "\(poem)"
        print("\(poem)")
        return poem
    }
    
    /*
     People poem structure #1
     {0:adj} {1:adj} eyes embedded in the {2:adj} face
     A {4:adj} mouth beneath {3:adj} nose
     The most {5:adj} person ever known
     Your {6:adj} {7:noun} lit up the New York City
     */
    
    func generatePeople1()->String{
        //image tags
        print(tagOne)
        let words = getWordClass(text: tagOne, language: "en")
        print(words)
        
        let wordClasses = ["Adjective", "Adjective", "Adjective", "Adjective", "Adjective", "Adjective", "Adjective", "Noun"]
        var chosenWords = [String]()
        for i in 0..<wordClasses.count{
            chosenWords.append(selectRandomWord(wordClass: wordClasses[i], imageTags: words))
        }
        var poem = chosenWords[0] + " " + chosenWords[1] + " eyes embedded in the " + chosenWords[2] + " face"
        poem += "\nA " + chosenWords[2] + " mouth beneath " + chosenWords[2] + " nose "
        poem += "\nThe most " + chosenWords[3] + " person ever known "
        poem += "\nYour " + chosenWords[5] + " " + chosenWords[6] + " blushes like a rose"
        
        
        // Output to text view element
        self.poeticText.text = "\(poem)"
        print("\(poem)")
        return poem
    }
    
    @IBAction func selectFont(_ sender: UIButton) {
        
        //call function to present user with text colour options
        print("User has selected to change font")
        bringChangeFontToView()
    }
    
    @IBAction func selectTextColour(_ sender: UIButton) {
        
        //call function to present user with text colour options
        print("User has selected to change colour")
        bringChangeColourToView()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch: UITouch? = touches.first
        
        // Dismiss the Change Text colour view if user doesnt select a colour
        if touch?.view != changeColourView {
            changeColourView.isHidden = true
        }
        
        // Dismiss the Change Font view if user doesnt select a font
        if touch?.view != changeColourView {
            changeFontView.isHidden = true
        }
    }
    
    @IBAction func changeTextColour(_ sender: UIButton) {
        
        switch sender.tag{
        case 0:
            poeticText.textColor = UIColor.black
            changeColourView.isHidden = true
            textColour.setImage(UIImage(named: "Black.png"), for: .normal)
            break;
        case 1:
            poeticText.textColor = UIColor.white
            changeColourView.isHidden = true
            textColour.setImage(UIImage(named: "White.png"), for: .normal)
            break;
        case 2:
            poeticText.textColor = UIColor.purple
            changeColourView.isHidden = true
            textColour.setImage(UIImage(named: "Purple.png"), for: .normal)
            break;
        case 3:
            poeticText.textColor = UIColor.blue
            changeColourView.isHidden = true
            textColour.setImage(UIImage(named: "Blue.png"), for: .normal)
            break;
        case 4:
            poeticText.textColor = UIColor.green
            changeColourView.isHidden = true
            textColour.setImage(UIImage(named: "Green.png"), for: .normal)
            break;
        case 5:
            poeticText.textColor = UIColor.yellow
            changeColourView.isHidden = true
            textColour.setImage(UIImage(named: "Yellow.png"), for: .normal)
            break;
        case 6:
            poeticText.textColor = UIColor.orange
            changeColourView.isHidden = true
            textColour.setImage(UIImage(named: "Orange.png"), for: .normal)
            break;
        case 7:
            poeticText.textColor = UIColor.red
            changeColourView.isHidden = true
            textColour.setImage(UIImage(named: "Red.png"), for: .normal)
            break;
        default: ()
        break;
        }
    }
    
    
    
// <-- REDIRECT THIS METHOD TO OTHER VC
   @IBAction func cancelSnap(_ sender: UIButton) {
//        // Confirm Cancellation.
//
//        print("User pressed back")
//        let defaultAction = UIAlertAction(title: "Okay",
//                                          style: .default) { (action) in
//                                            // Respond to user selection of the action.
//                                            self.setupInitialUI()
//
//        }
//        let cancelAction = UIAlertAction(title: "Cancel",
//                                         style: .cancel) { (action) in
//                                            // Respond to user selection of the action.
//        }
//
//        // Create and configure the alert controller.
//        let alert = UIAlertController(title: "Cancel",
//                                      message: "All changes will be lost. Continue?",
//                                      preferredStyle: .alert)
//        alert.addAction(defaultAction)
//        alert.addAction(cancelAction)
//
//        self.present(alert, animated: true) {
//            // The alert was presented
//
//        }
//
    }
    
    
    func setupPhotoUI(){
        
        //** CONFIGURE OVERALL LAYOUT
        let contentView = UIView()
        view.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        
        //** CONFIGURE PHOTO DISPLAYED VIEW
        contentView.addSubview(photoTaken)
        photoTaken.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(contentView)
            make.left.right.equalTo(contentView)
        }

        //*** SHARE BUTTON
        contentView.addSubview(shareNavButton)
        contentView.bringSubview(toFront: shareNavButton)
        shareNavButton.snp.makeConstraints { (make) in
            make.top.equalTo(contentView).offset(20)
            make.right.equalTo(contentView).offset(-20)
            make.width.height.equalTo(50)
        }

        //*** BACK BUTTON
        contentView.addSubview(backNavButton)
        contentView.bringSubview(toFront: backNavButton)
        backNavButton.snp.makeConstraints { (make) in
            make.left.equalTo(contentView).offset(10)
            make.centerY.equalTo(shareNavButton.snp.centerY)
            make.width.height.equalTo(50)
        }

        //*** SAVE BUTTON
        photoTaken.addSubview(savePhoto)
        photoTaken.bringSubview(toFront: savePhoto)
        savePhoto.snp.makeConstraints { (make) in
            make.centerX.equalTo(photoTaken.snp.centerX)
            make.centerY.equalTo(shareNavButton.snp.centerY)
            //make.width.height.equalTo(50)
        }

        //*** POETIC TEXT
        photoTaken.addSubview(poeticText)
        poeticText.font = UIFont(name: "HelveticaNeue-Light", size: 20.0)
        poeticText.textAlignment = NSTextAlignment.center
        poeticText.textColor = .black
        poeticText.layer.shadowColor = UIColor.black.cgColor
        poeticText.layer.shadowOpacity = 0.9
        poeticText.layer.shadowOffset = CGSize(width: 0.5, height: 0.5)

        photoTaken.bringSubview(toFront: poeticText)
        poeticText.snp.makeConstraints { (make) in
            make.top.equalTo(photoTaken.snp.centerY).offset(-50)
            make.width.equalTo(photoTaken).multipliedBy(0.8)
            make.centerX.equalTo(photoTaken.snp.centerX)
            make.height.equalTo(300)

        }

        //** CONFIGURE COLOUR BUTTON SINGLE
        contentView.addSubview(textColour)
        contentView.bringSubview(toFront: textColour)
        textColour.snp.makeConstraints { (make) in
            make.bottom.equalTo(contentView.snp.bottom)
            make.right.equalTo(contentView.snp.right)
            make.height.width.equalTo(50)
        }
        
            //** CONFIGURE FONT BUTTON SINGLE
        contentView.addSubview(fontStyle)
        contentView.bringSubview(toFront: fontStyle)
        fontStyle.snp.makeConstraints { (make) in
            make.bottom.equalTo(contentView.snp.bottom)
            make.right.equalTo(textColour.snp.left).offset(-10)
            make.height.width.equalTo(50)
        }
    }
    
    func bringChangeFontToView()
    {
        //create view to house fonts
        
        changeFontView.isHidden = false
        changeFontView.backgroundColor = .orange
        changeFontView.snp.makeConstraints { (make) in
            make.centerX.equalTo(view.snp.centerX)
            make.width.equalTo(view).multipliedBy(0.9)
            make.height.equalTo(100)
        }
    }
    
    
    func bringChangeColourToView()
    {
        
        // create view to house all colours
        changeColourView.isHidden = false
        view.addSubview(changeColourView)
        view.bringSubview(toFront: changeColourView)
        changeColourView.snp.makeConstraints { (make) in
            make.centerX.equalTo(view.snp.centerX)
            make.width.equalTo(view).multipliedBy(0.9)
            make.bottom.equalTo(textColour.snp.top).offset(-30)
            make.height.equalTo(50)
        }
        
        // lay out each colour within view
        changeColourView.addSubview(colourBlack)
        changeColourView.bringSubview(toFront: colourBlack)
        colourBlack.snp.makeConstraints { (make) in
            make.width.equalTo(changeColourView).dividedBy(10)
            make.left.equalTo(changeColourView.snp.left)
            make.centerY.equalTo(changeColourView.snp.centerY)
            make.height.equalTo(colourBlack.snp.width)
        }
        
        changeColourView.addSubview(colourWhite)
        changeColourView.bringSubview(toFront: colourWhite)
        colourWhite.snp.makeConstraints { (make) in
            make.width.equalTo(changeColourView).dividedBy(10)
            make.left.equalTo(colourBlack.snp.right).offset(10)
            make.centerY.equalTo(changeColourView.snp.centerY)
            make.height.equalTo(colourWhite.snp.width)
        }
        
        changeColourView.addSubview(colourPurple)
        changeColourView.bringSubview(toFront: colourPurple)
        colourPurple.snp.makeConstraints { (make) in
            make.width.equalTo(changeColourView).dividedBy(10)
            make.left.equalTo(colourWhite.snp.right).offset(10)
            make.centerY.equalTo(changeColourView.snp.centerY)
            make.height.equalTo(colourPurple.snp.width)
        }
        
        changeColourView.addSubview(colourBlue)
        changeColourView.bringSubview(toFront: colourBlue)
        colourBlue.snp.makeConstraints { (make) in
            make.width.equalTo(changeColourView).dividedBy(10)
            make.left.equalTo(colourPurple.snp.right).offset(10)
            make.centerY.equalTo(changeColourView.snp.centerY)
            make.height.equalTo(colourBlue.snp.width)
        }
        
        changeColourView.addSubview(colourGreen)
        changeColourView.bringSubview(toFront: colourGreen)
        colourGreen.snp.makeConstraints { (make) in
            make.width.equalTo(changeColourView).dividedBy(10)
            make.left.equalTo(colourBlue.snp.right).offset(10)
            make.centerY.equalTo(changeColourView.snp.centerY)
            make.height.equalTo(colourGreen.snp.width)
        }
        
        changeColourView.addSubview(colourYellow)
        changeColourView.bringSubview(toFront: colourYellow)
        colourYellow.snp.makeConstraints { (make) in
            make.width.equalTo(changeColourView).dividedBy(10)
            make.left.equalTo(colourGreen.snp.right).offset(10)
            make.centerY.equalTo(changeColourView.snp.centerY)
            make.height.equalTo(colourYellow.snp.width)
        }
        
        changeColourView.addSubview(colourOrange)
        changeColourView.bringSubview(toFront: colourOrange)
        colourOrange.snp.makeConstraints { (make) in
            make.width.equalTo(changeColourView).dividedBy(10)
            make.left.equalTo(colourYellow.snp.right).offset(10)
            make.centerY.equalTo(changeColourView.snp.centerY)
            make.height.equalTo(colourOrange.snp.width)
        }
        
        changeColourView.addSubview(colourRed)
        changeColourView.bringSubview(toFront: colourYellow)
        colourRed.snp.makeConstraints { (make) in
            make.width.equalTo(changeColourView).dividedBy(10)
            make.left.equalTo(colourOrange.snp.right).offset(10)
            make.centerY.equalTo(changeColourView.snp.centerY)
            make.height.equalTo(colourRed.snp.width)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}