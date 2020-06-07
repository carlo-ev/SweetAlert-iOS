//
//  SweetAlert.swift
//  SweetAlert
//
//  Created by Codester on 11/3/14.
//  Copyright (c) 2014 Codester. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

public enum AlertStyle {
    case success,error,warning,none,loading
    case customImag(imageFile:String)
}
public func ==(left: AlertStyle, right: AlertStyle) -> Bool{
    switch (left, right){
        case (.success, .success): return true
        case (.error, .error): return true
        case (.warning, .warning): return true
        case (.none, .none): return true
        case (.loading, .loading): return true
        case (.customImag(let rFile), .customImag(let lFile)) where rFile == lFile: return true
        default: return false
    }
}

open class SweetAlert: UIViewController {
    let kBakcgroundTansperancy: CGFloat = 0.7
    let kHeightMargin: CGFloat = 10.0
    let KTopMargin: CGFloat = 20.0
    let kWidthMargin: CGFloat = 10.0
    let kAnimatedViewHeight: CGFloat = 70.0
    let kMaxHeight: CGFloat = 700.0
    var kContentWidth: CGFloat = 300.0//Utils.displayedOnCompactDevice ? 300.0 : 600.00
    let kButtonHeight: CGFloat = 35.0
    var textViewHeight: CGFloat = 90.0
    let kTitleHeight:CGFloat = 30.0
    var strongSelf:SweetAlert?
    var contentView = UIView()
    var titleLabel: UILabel = UILabel()
    var buttons: [UIButton] = []
    var animatedView: AnimatableView?
    var imageView:UIImageView?
    var subTitleTextView = UITextView()
    var userAction:((_ isOtherButton: Bool) -> Void)? = nil
    let kFont = "Helvetica"

    init() {
        super.init(nibName: nil, bundle: nil)
        self.view.frame = UIScreen.main.bounds
        self.view.autoresizingMask = [UIViewAutoresizing.flexibleHeight, UIViewAutoresizing.flexibleWidth]
        self.view.backgroundColor = UIColor(red:0, green:0, blue:0, alpha:kBakcgroundTansperancy)
        self.view.addSubview(contentView)
        
        //Retaining itself strongly so can exist without strong refrence
        strongSelf = self
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setupContentView() {
        contentView.backgroundColor = UIColor(white: 1.0, alpha: 1.0)
        contentView.layer.cornerRadius = 5.0
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 0.5
        contentView.addSubview(titleLabel)
        contentView.addSubview(subTitleTextView)
        contentView.backgroundColor = UIColor.colorFromRGB(0xFFFFFF)
        contentView.layer.borderColor = UIColor.colorFromRGB(0xCCCCCC).cgColor
        view.addSubview(contentView)
    }

    fileprivate func setupTitleLabel() {
        titleLabel.text = ""
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont(name: kFont, size:25)
        titleLabel.textColor = UIColor.colorFromRGB(0x575757)
    }
    
    fileprivate func setupSubtitleTextView() {
        subTitleTextView.text = ""
        subTitleTextView.textAlignment = .center
        subTitleTextView.font = UIFont(name: kFont, size:16)
        subTitleTextView.textColor = UIColor.colorFromRGB(0x797979)
        subTitleTextView.isEditable = false
    }
    
    fileprivate func resizeAndRelayout() {
        let mainScreenBounds = UIScreen.main.bounds
        self.view.frame.size = mainScreenBounds.size
        let x: CGFloat = kWidthMargin
        var y: CGFloat = KTopMargin
        let width: CGFloat = kContentWidth - (kWidthMargin*2)
        
        if animatedView != nil {
             animatedView!.frame = CGRect(x: (kContentWidth - kAnimatedViewHeight) / 2.0, y: y, width: kAnimatedViewHeight, height: kAnimatedViewHeight)
            contentView.addSubview(animatedView!)
            y += kAnimatedViewHeight + kHeightMargin
        }
        
        if imageView != nil {
            imageView!.frame = CGRect(x: (kContentWidth - kAnimatedViewHeight) / 2.0, y: y, width: kAnimatedViewHeight, height: kAnimatedViewHeight)
            contentView.addSubview(imageView!)
            y += imageView!.frame.size.height + kHeightMargin
        }

        // Title
        if self.titleLabel.text != nil {
            let properHeight = titleLabel.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)).height
            titleLabel.frame = CGRect(x: x, y: y, width: width, height: properHeight)//kTitleHeight)
            contentView.addSubview(titleLabel)
            y += /*kTitleHeight*/ properHeight + kHeightMargin
        }
        
        // Subtitle
        if self.subTitleTextView.text.isEmpty == false {
            let size = subTitleTextView.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
            textViewHeight = size.height + 10.0
            subTitleTextView.frame = CGRect(x: x, y: y, width: width, height: textViewHeight)
            contentView.addSubview(subTitleTextView)
            y += textViewHeight + kHeightMargin
        }
        
        var buttonRect:[CGRect] = []
        for button in buttons {
            let string = button.title(for: UIControlState())! as NSString
            buttonRect.append(string.boundingRect(with: CGSize(width: width, height:0.0), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes:[NSAttributedStringKey.font:button.titleLabel!.font], context:nil))
        }
        
        var totalWidth: CGFloat = 0.0
        if buttons.count==2{
            totalWidth = buttonRect[0].size.width + buttonRect[1].size.width + kWidthMargin + 40.0
        }
        else if buttons.count==1{
            totalWidth = buttonRect[0].size.width + 20.0
        }
        y += kHeightMargin
        var buttonX = (kContentWidth - totalWidth ) / 2.0
        for i in 0 ..< buttons.count {
            
                buttons[i].frame = CGRect(x: buttonX, y: y, width: buttonRect[i].size.width + 20.0, height: buttonRect[i].size.height + 10.0)
                buttonX = buttons[i].frame.origin.x + kWidthMargin + buttonRect[i].size.width + 20.0
                buttons[i].layer.cornerRadius = 5.0
                self.contentView.addSubview(buttons[i])
                buttons[i].addTarget(self, action: #selector(SweetAlert.pressed(_:)), for: UIControlEvents.touchUpInside)

        }
        if buttons.count>0{
            y += kHeightMargin + buttonRect[0].size.height + 10.0
        }
        if y > kMaxHeight {
            let diff = y - kMaxHeight
            let sFrame = subTitleTextView.frame
            subTitleTextView.frame = CGRect(x: sFrame.origin.x, y: sFrame.origin.y, width: sFrame.width, height: sFrame.height - diff)

            for button in buttons {
                let bFrame = button.frame
                button.frame = CGRect(x: bFrame.origin.x, y: bFrame.origin.y - diff, width: bFrame.width, height: bFrame.height)
            }

            y = kMaxHeight
        }

        contentView.frame = CGRect(x: (mainScreenBounds.size.width - kContentWidth) / 2.0, y: (mainScreenBounds.size.height - y) / 2.0, width: kContentWidth, height: y)
        contentView.clipsToBounds = true
    }
    
    @objc open func pressed(_ sender: UIButton!) {
        self.closeAlert(sender.tag)
    }

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        var sz = UIScreen.main.bounds.size
        let sver = UIDevice.current.systemVersion as NSString
        let ver = sver.floatValue
        if ver < 8.0 {
            // iOS versions before 7.0 did not switch the width and height on device roration
            if UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation) {
                let ssz = sz
                sz = CGSize(width:ssz.height, height:ssz.width)
            }
        }
        self.resizeAndRelayout()
    }

    func closeAlert(_ buttonIndex:Int){
        if userAction !=  nil {
            let isOtherButton = buttonIndex == 0 ? true: false
            SweetAlertContext.shouldNotAnimate = true
            userAction!(isOtherButton)
            SweetAlertContext.shouldNotAnimate = false
        }

        UIView.animate(withDuration: 0.5, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: { () -> Void in
            self.view.alpha = 0.0
        }) { (Bool) -> Void in
            self.view.removeFromSuperview()
            self.cleanUpAlert()
            
            //Releasing strong refrence of itself.
            self.strongSelf = nil
        }
    }

    func cleanUpAlert() {
    
        if self.animatedView != nil {
            self.animatedView!.removeFromSuperview()
            self.animatedView = nil
        }
        self.contentView.removeFromSuperview()
        self.contentView = UIView()
    }
    
    open func showAlert(_ title: String) -> SweetAlert {
        let _ = self.showAlert(title, subTitle: nil, style: .none)
        return self
    }
    
    open func showAlert(_ title: String, subTitle: String?, style: AlertStyle) -> SweetAlert {
        let _ = self.showAlert(title, subTitle: subTitle, style: style, buttonTitle: "OK")
        return self

    }

    open func showAlert(_ title: String, subTitle: String?, style: AlertStyle,buttonTitle: String, action: ((_ isOtherButton: Bool) -> Void)? = nil) -> SweetAlert {
        let _ = self.showAlert(title, subTitle: subTitle, style: style, buttonTitle: buttonTitle,buttonColor: UIColor.colorFromRGB(0xAEDEF4))
        userAction = action
        return self
    }
    
    open func showAlert(_ title: String, subTitle: String?, style: AlertStyle,buttonTitle: String,buttonColor: UIColor,action: ((_ isOtherButton: Bool) -> Void)? = nil) -> SweetAlert {
        let _ = self.showAlert(title, subTitle: subTitle, style: style, buttonTitle: buttonTitle,buttonColor: buttonColor,otherButtonTitle:
            nil)
        userAction = action
        return self
    }

    open func showAlert(_ title: String, subTitle: String?, style: AlertStyle,buttonTitle: String,buttonColor: UIColor,otherButtonTitle:
        String?, action: ((_ isOtherButton: Bool) -> Void)? = nil) -> SweetAlert {
            self.showAlert(title, subTitle: subTitle, style: style, buttonTitle: buttonTitle,buttonColor: buttonColor,otherButtonTitle:
                otherButtonTitle,otherButtonColor: UIColor.red)
            userAction = action
            return self
    }
    
    open func showAlert(_ title: String, subTitle: String?, style: AlertStyle,buttonTitle: String,buttonColor: UIColor,otherButtonTitle:
        String?, otherButtonColor: UIColor?,action: ((_ isOtherButton: Bool) -> Void)? = nil) {
            userAction = action
            let window: UIWindow = UIApplication.shared.keyWindow! 
            window.addSubview(view)
            window.bringSubview(toFront: view)
            view.frame = window.bounds
            self.setupContentView()
        
            self.setupTitleLabel()
            self.setupSubtitleTextView()
 
            switch style {
            case .success:
                self.animatedView = SuccessAnimatedView()
            case .error:
                self.animatedView = CancelAnimatedView()
            case .loading:
                self.animatedView = LoadingAnimatedView()
            case .warning:
                self.animatedView = InfoAnimatedView()
            case let .customImag(imageFile):
                if let image = UIImage(named: imageFile) {
                    self.imageView = UIImageView(image: image)
                }
            case .none:
                self.animatedView = nil
            }
            /*
            if style == AlertStyle.Loading {
                self.imageView?.image=UIImage(named: "ic_jsa_template")!
            }
            */
            titleLabel.text=title
            if subTitle != nil {
                self.subTitleTextView.text = subTitle
            }
            buttons = []
            if buttonTitle.isEmpty == false && !(style == .loading){
                let button: UIButton = UIButton(type: UIButtonType.custom)
                button.setTitle(buttonTitle, for: UIControlState())
                button.backgroundColor = buttonColor
                button.isUserInteractionEnabled = true
                button.tag = 0
                buttons.append(button)
            }
            
            if otherButtonTitle != nil && otherButtonTitle!.isEmpty == false {
                let button: UIButton = UIButton(type: UIButtonType.custom)
                button.setTitle(otherButtonTitle, for: UIControlState())
                button.backgroundColor = otherButtonColor
                button.addTarget(self, action: #selector(SweetAlert.pressed(_:)), for: UIControlEvents.touchUpInside)
                button.tag = 1
                buttons.append(button)
            }

            resizeAndRelayout()
            if SweetAlertContext.shouldNotAnimate == true {
                //Do not animate Alert
                if self.animatedView != nil {
                    self.animatedView!.animate()
                }
            }
            else {
                animateAlert()
            }
    }
    
    open func showAlert(_ title: String, subTitle: NSMutableAttributedString?, style: AlertStyle,buttonTitle: String,buttonColor: UIColor,otherButtonTitle:
        String?, otherButtonColor: UIColor?,action: ((_ isOtherButton: Bool) -> Void)? = nil) {
        userAction = action
        let window: UIWindow = UIApplication.shared.keyWindow!
        window.addSubview(view)
        window.bringSubview(toFront: view)
        view.frame = window.bounds
        self.setupContentView()
        
        self.setupTitleLabel()
        self.setupSubtitleTextView()
        
        switch style {
        case .success:
            self.animatedView = SuccessAnimatedView()
        case .error:
            self.animatedView = CancelAnimatedView()
        case .loading:
            self.animatedView = LoadingAnimatedView()
        case .warning:
            self.animatedView = InfoAnimatedView()
        case let .customImag(imageFile):
            if let image = UIImage(named: imageFile) {
                self.imageView = UIImageView(image: image)
            }
        case .none:
            self.animatedView = nil
        }
        /*
         if style == AlertStyle.Loading {
         self.imageView?.image=UIImage(named: "ic_jsa_template")!
         }
         */
        titleLabel.text=title
        if subTitle != nil {
            self.subTitleTextView.attributedText = subTitle
        }
        buttons = []
        if buttonTitle.isEmpty == false && !(style == .loading){
            let button: UIButton = UIButton(type: UIButtonType.custom)
            button.setTitle(buttonTitle, for: UIControlState())
            button.backgroundColor = buttonColor
            button.isUserInteractionEnabled = true
            button.tag = 0
            buttons.append(button)
        }
        
        if otherButtonTitle != nil && otherButtonTitle!.isEmpty == false {
            let button: UIButton = UIButton(type: UIButtonType.custom)
            button.setTitle(otherButtonTitle, for: UIControlState())
            button.backgroundColor = otherButtonColor
            button.addTarget(self, action: #selector(SweetAlert.pressed(_:)), for: UIControlEvents.touchUpInside)
            button.tag = 1
            buttons.append(button)
        }
        
        resizeAndRelayout()
        if SweetAlertContext.shouldNotAnimate == true {
            //Do not animate Alert
            if self.animatedView != nil {
                self.animatedView!.animate()
            }
        }
        else {
            animateAlert()
        }
    }

    func animateAlert() {

        view.alpha = 0;
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.view.alpha = 1.0;
        })

        let previousTransform = self.contentView.transform
        self.contentView.layer.transform = CATransform3DMakeScale(0.9, 0.9, 0.0);
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.contentView.layer.transform = CATransform3DMakeScale(1.1, 1.1, 0.0);
            }, completion: { (Bool) -> Void in
                UIView.animate(withDuration: 0.1, animations: { () -> Void in
                    self.contentView.layer.transform = CATransform3DMakeScale(0.9, 0.9, 0.0);
                    }, completion: { (Bool) -> Void in
                        UIView.animate(withDuration: 0.1, animations: { () -> Void in
                            self.contentView.layer.transform = CATransform3DMakeScale(1.0, 1.0, 0.0);
                            if self.animatedView != nil {
                                self.animatedView!.animate()
                            }

                            }, completion: { (Bool) -> Void in

                                self.contentView.transform = previousTransform
                        }) 
                }) 
        }) 
    }
    
    fileprivate struct SweetAlertContext {
        static var shouldNotAnimate = false
    }
}

// MARK: -

// MARK: Animatable Views

class AnimatableView: UIView {
    func animate(){
        print("Should overide by subclasss", terminator: "")
    }
}

class LoadingAnimatedView: AnimatableView{
    var circleAnimation: CAShapeLayer = CAShapeLayer()
    fileprivate var circlePath: CGPath {
        let path = UIBezierPath()
        let startAngle: CGFloat = 0
        let endAngle: CGFloat = CGFloat(2*Double.pi)
        path.addArc(withCenter: CGPoint(x: self.frame.size.width/2.0, y: self.frame.size.width/2.0), radius: self.frame.size.width/2.0, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        return path.cgPath
    }
    override required init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    override func layoutSubviews() {
        setupLayers()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //fatalError("init(coder:) has not been implemented")
    }
    fileprivate func setupLayers(){
        circleAnimation.path = circlePath
        circleAnimation.fillColor=UIColor.clear.cgColor
        circleAnimation.strokeColor=UIColor.colorFromRGB(0x2960FF).cgColor
        circleAnimation.lineCap=kCALineCapRound
        circleAnimation.lineWidth=4
        circleAnimation.frame=CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        circleAnimation.position=CGPoint(x: self.frame.size.width/2.0, y: self.frame.size.height/2.0)
        layer.addSublayer(circleAnimation)
        CATransaction.begin()
        circleAnimation.strokeStart=0.25
        CATransaction.commit()
    }
    override func animate() {
        let animation=CABasicAnimation(keyPath: "transform.rotation")
        animation.duration=2.0
        animation.byValue=NSNumber(value: 2*Double.pi as Double)
        animation.repeatCount = Float.infinity
        
        let shrinkAnimation = CABasicAnimation(keyPath: "strokeStart")
        shrinkAnimation.duration=0.75
        shrinkAnimation.isRemovedOnCompletion=false
        shrinkAnimation.fromValue=0.25
        shrinkAnimation.toValue=0.9999
        shrinkAnimation.fillMode=kCAFillModeForwards
        shrinkAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        let moveToStart = CABasicAnimation(keyPath: "strokeStart")
        moveToStart.duration=0.001
        moveToStart.isRemovedOnCompletion=false
        moveToStart.fromValue=0
        moveToStart.toValue=0
        moveToStart.beginTime=0.75
        moveToStart.fillMode=kCAFillModeForwards
        moveToStart.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        let moveEndToStart = CABasicAnimation(keyPath: "stokeEnd")
        moveEndToStart.duration=0.001
        moveEndToStart.isRemovedOnCompletion=false
        moveEndToStart.fromValue=0
        moveEndToStart.toValue=0.001
        moveEndToStart.beginTime=0.75
        moveEndToStart.fillMode=kCAFillModeForwards
        moveEndToStart.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        let moveStartAnimation = CABasicAnimation(keyPath: "strokeStart")
        moveStartAnimation.duration=0.75
        moveStartAnimation.isRemovedOnCompletion=false
        moveStartAnimation.fromValue=0
        moveStartAnimation.toValue=0.25
        moveStartAnimation.beginTime=0.7501
        moveStartAnimation.fillMode=kCAFillModeForwards
        moveStartAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        let growAnimation = CABasicAnimation(keyPath: "strokeEnd")
        growAnimation.duration=0.75
        growAnimation.isRemovedOnCompletion=false
        growAnimation.fromValue=0.001
        growAnimation.toValue=1
        growAnimation.beginTime=0.7501
        growAnimation.fillMode=kCAFillModeForwards
        growAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        let groupAnimations = CAAnimationGroup()
        groupAnimations.animations = [shrinkAnimation,moveEndToStart,moveToStart,growAnimation,moveStartAnimation]
        groupAnimations.repeatCount=Float.infinity
        groupAnimations.duration=1.5001
        groupAnimations.fillMode=kCAFillModeForwards
        
        
        circleAnimation.add(groupAnimations, forKey: "drawAnimation")
        circleAnimation.add(animation, forKey: "rotateAnimation")
    }
}

class CancelAnimatedView: AnimatableView {
    
    var circleLayer = CAShapeLayer()
    var crossPathLayer = CAShapeLayer()

    override required init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
        var t = CATransform3DIdentity;
        t.m34 = 1.0 / -500.0;
        t = CATransform3DRotate(t, CGFloat(90.0 * Double.pi / 180.0), 1, 0, 0);
        circleLayer.transform = t
        crossPathLayer.opacity = 0.0
    }
    
    override func layoutSubviews() {
        setupLayers()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
     fileprivate var outlineCircle: CGPath  {
        let path = UIBezierPath()
        let startAngle: CGFloat = CGFloat((0) / 180.0 * Double.pi)  //0
        let endAngle: CGFloat = CGFloat((360) / 180.0 * Double.pi)   //360
        path.addArc(withCenter: CGPoint(x: self.frame.size.width/2.0, y: self.frame.size.width/2.0), radius: self.frame.size.width/2.0, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        
        return path.cgPath
        }
    
    fileprivate var crossPath: CGPath  {
        let path = UIBezierPath()
        let factor:CGFloat = self.frame.size.width / 5.0
        path.move(to: CGPoint(x: self.frame.size.height/2.0-factor,y: self.frame.size.height/2.0-factor))
        path.addLine(to: CGPoint(x: self.frame.size.height/2.0+factor,y: self.frame.size.height/2.0+factor))
        path.move(to: CGPoint(x: self.frame.size.height/2.0+factor,y: self.frame.size.height/2.0-factor))
        path.addLine(to: CGPoint(x: self.frame.size.height/2.0-factor,y: self.frame.size.height/2.0+factor))
        
        return path.cgPath
    }
    
    fileprivate func setupLayers() {
        circleLayer.path = outlineCircle
        circleLayer.fillColor = UIColor.clear.cgColor;
        circleLayer.strokeColor = UIColor.colorFromRGB(0xF27474).cgColor;
        circleLayer.lineCap = kCALineCapRound
        circleLayer.lineWidth = 4;
        circleLayer.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        circleLayer.position = CGPoint(x: self.frame.size.width/2.0, y: self.frame.size.height/2.0)
        self.layer.addSublayer(circleLayer)
        
        crossPathLayer.path = crossPath
        crossPathLayer.fillColor = UIColor.clear.cgColor;
        crossPathLayer.strokeColor = UIColor.colorFromRGB(0xF27474).cgColor;
        crossPathLayer.lineCap = kCALineCapRound
        crossPathLayer.lineWidth = 4;
        crossPathLayer.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        crossPathLayer.position = CGPoint(x: self.frame.size.width/2.0, y: self.frame.size.height/2.0)
        self.layer.addSublayer(crossPathLayer)

    }
    
    override func animate() {
        var t = CATransform3DIdentity;
        t.m34 = 1.0 / -500.0;
        t = CATransform3DRotate(t, CGFloat(90.0 * Double.pi / 180.0), 1, 0, 0);
        
        var t2 = CATransform3DIdentity;
        t2.m34 = 1.0 / -500.0;
        t2 = CATransform3DRotate(t2, CGFloat(-Double.pi), 1, 0, 0);

        let animation = CABasicAnimation(keyPath: "transform")
        let time = 0.3
        animation.duration = time;
        animation.fromValue = NSValue(caTransform3D: t)
        animation.toValue = NSValue(caTransform3D:t2)
        animation.isRemovedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        self.circleLayer.add(animation, forKey: "transform")
        
        
        var scale = CATransform3DIdentity;
        scale = CATransform3DScale(scale, 0.3, 0.3, 0)

        
        let crossAnimation = CABasicAnimation(keyPath: "transform")
        crossAnimation.duration = 0.3;
        crossAnimation.beginTime = CACurrentMediaTime() + time
        crossAnimation.fromValue = NSValue(caTransform3D: scale)
        crossAnimation.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.8, 0.7, 2.0)
        crossAnimation.toValue = NSValue(caTransform3D:CATransform3DIdentity)
        self.crossPathLayer.add(crossAnimation, forKey: "scale")
        
        let fadeInAnimation = CABasicAnimation(keyPath: "opacity")
        fadeInAnimation.duration = 0.3;
        fadeInAnimation.beginTime = CACurrentMediaTime() + time
        fadeInAnimation.fromValue = 0.3
        fadeInAnimation.toValue = 1.0
        fadeInAnimation.isRemovedOnCompletion = false
        fadeInAnimation.fillMode = kCAFillModeForwards
        self.crossPathLayer.add(fadeInAnimation, forKey: "opacity")
    }
    
}

class InfoAnimatedView: AnimatableView {
    
    var circleLayer = CAShapeLayer()
    var crossPathLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    override func layoutSubviews() {
        setupLayers()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var outlineCircle: CGPath  {
        let path = UIBezierPath()
        let startAngle: CGFloat = CGFloat((0) / 180.0 * Double.pi)  //0
        let endAngle: CGFloat = CGFloat((360) / 180.0 * Double.pi)   //360
        path.addArc(withCenter: CGPoint(x: self.frame.size.width/2.0, y: self.frame.size.width/2.0), radius: self.frame.size.width/2.0, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        
        let factor:CGFloat = self.frame.size.width / 1.5
        path.move(to: CGPoint(x: self.frame.size.width/2.0 , y: 15.0))
        path.addLine(to: CGPoint(x: self.frame.size.width/2.0,y: factor))
        path.move(to: CGPoint(x: self.frame.size.width/2.0,y: factor + 10.0))
        path.addArc(withCenter: CGPoint(x: self.frame.size.width/2.0,y: factor + 10.0), radius: 1.0, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        
        return path.cgPath
    }
    
    func setupLayers() {
        circleLayer.path = outlineCircle
        circleLayer.fillColor = UIColor.clear.cgColor;
        circleLayer.strokeColor = UIColor.colorFromRGB(0xF8D486).cgColor;
        circleLayer.lineCap = kCALineCapRound
        circleLayer.lineWidth = 4;
        circleLayer.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        circleLayer.position = CGPoint(x: self.frame.size.width/2.0, y: self.frame.size.height/2.0)
        self.layer.addSublayer(circleLayer)
    }
    
    override func animate() {
        
        let colorAnimation = CABasicAnimation(keyPath:"strokeColor")
        colorAnimation.duration = 1.0;
        colorAnimation.repeatCount = HUGE
        colorAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        colorAnimation.autoreverses = true
        colorAnimation.fromValue = UIColor.colorFromRGB(0xF7D58B).cgColor
        colorAnimation.toValue = UIColor.colorFromRGB(0xF2A665).cgColor
        circleLayer.add(colorAnimation, forKey: "strokeColor")
    }
}


class SuccessAnimatedView: AnimatableView {
    
    var circleLayer = CAShapeLayer()
    var outlineLayer = CAShapeLayer()

    var isSmall: Bool=false
    var strokeColor: CGColor=UIColor(red: 150.0/255.0, green: 216.0/255.0, blue: 115.0/255.0, alpha: 1.0).cgColor
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
        circleLayer.strokeStart = 0.0
        circleLayer.strokeEnd = 0.0
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayers()
        circleLayer.strokeStart = 0.0
        circleLayer.strokeEnd = 0.0
        //fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        setupLayers()
    }

    
    var outlineCircle: CGPath {
        let path = UIBezierPath()
        let startAngle: CGFloat = CGFloat((0) / 180.0 * Double.pi)  //0
        let endAngle: CGFloat = CGFloat((360) / 180.0 * Double.pi)   //360
        path.addArc(withCenter: CGPoint(x: self.frame.size.width/2.0, y: self.frame.size.height/2.0), radius: self.frame.size.width/2.0, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return path.cgPath
    }
    
    var path: CGPath {
        let path = UIBezierPath()
        let startAngle:CGFloat = CGFloat((60) / 180.0 * Double.pi) //60
        let endAngle:CGFloat = CGFloat((200) / 180.0 * Double.pi)  //190
        path.addArc(withCenter: CGPoint(x: self.frame.size.width/2.0, y: self.frame.size.height/2.0), radius: self.frame.size.width/2.0, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addLine(to: CGPoint(x: 36.0 - 10.0 ,y: 60.0 - 10.0))
        path.addLine(to: CGPoint(x: 85.0 - 20.0, y: 30.0 - 20.0))
        return path.cgPath
    }

    var smallPath: CGPath {
        let path = UIBezierPath()
        let startAngle:CGFloat = CGFloat((60) / 180.0 * Double.pi) //60
        let endAngle:CGFloat = CGFloat((200) / 180.0 * Double.pi)  //190
        path.addArc(withCenter: CGPoint(x: self.frame.size.width/2.0, y: self.frame.size.height/2.0), radius: self.frame.size.width/2.0, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addLine(to: CGPoint(x: 14.0 ,y: 26.0))
        path.addLine(to: CGPoint(x: 33.0, y: 5.0))
        return path.cgPath
    }
    
    
    func setupLayers() {
        
        outlineLayer.position = CGPoint(x: 0,
            y: 0);
        outlineLayer.path = outlineCircle
        outlineLayer.fillColor = UIColor.clear.cgColor;
        outlineLayer.strokeColor = strokeColor;
        outlineLayer.lineCap = kCALineCapRound
        outlineLayer.lineWidth = 4;
        outlineLayer.opacity = 0.1
        self.layer.addSublayer(outlineLayer)
        
        circleLayer.position = CGPoint(x: 0,
            y: 0);
        if isSmall{
            circleLayer.path = smallPath;
            circleLayer.lineWidth = 3;
        }else{
            circleLayer.path = path;
            circleLayer.lineWidth = 4;
        }
        circleLayer.fillColor = UIColor.clear.cgColor;
        circleLayer.strokeColor = strokeColor
        circleLayer.lineCap = kCALineCapRound
        
        circleLayer.actions = [
            "strokeStart": NSNull(),
            "strokeEnd": NSNull(),
            "transform": NSNull()
        ]
        self.layer.addSublayer(circleLayer)
    }
    
    override func animate() {
        circleLayer.removeAllAnimations()
        
        let strokeStart = CABasicAnimation(keyPath: "strokeStart")
        let strokeEnd = CABasicAnimation(keyPath: "strokeEnd")
        let factor = 0.045
        strokeEnd.fromValue = 0.00
        strokeEnd.toValue = 0.93
        strokeEnd.duration = 10.0*factor
        let timing = CAMediaTimingFunction(controlPoints: 0.3, 0.6, 0.8, 1.2)
        strokeEnd.timingFunction = timing
        
        strokeStart.fromValue = 0.0
        strokeStart.toValue = 0.68
        strokeStart.duration =  7.0*factor
        strokeStart.beginTime =  CACurrentMediaTime() + 3.0*factor
        strokeStart.fillMode = kCAFillModeBackwards
        strokeStart.timingFunction = timing
        circleLayer.strokeStart = 0.68
        circleLayer.strokeEnd = 0.93
        self.circleLayer.add(strokeEnd, forKey: "strokeEnd")
        self.circleLayer.add(strokeStart, forKey: "strokeStart")
    }
    
}

extension UIColor {
    class func colorFromRGB(_ rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

