//
//  CustomTransitionAnimator.swift
//  CustomTransitionAnimator
//
//  Created by Broccoli on 15/11/24.
//  Copyright © 2015年 Broccoli. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

/// CustomTransitionAnimator 这个对象做为 要做转场动画的ViewControlle.transitioningDelegate
//  transitioningDelegate 的类型是 <UIViewControllerTransitioningDelegate> 那就在 Step 1: 实现这个协议

// UIPercentDrivenInteractiveTransition             百分比 交互 转场  Class
// 那么你可能要问了 为什么我们要继承 UIPercentDrivenInteractiveTransition
// 因为 Step 2: 做完了之后 会调用 Step 1: 中的 第三/四个方法 interactionControllerForPresentation 这个时候 要返回一个 UIViewControllerInteractiveTransitioning 类型的对象
// 你是不是被绕晕了..........
// 你会惊喜的发现 UIPercentDrivenInteractiveTransition: UIViewControllerInteractiveTransitioning
// 所以 你就可以省去很多麻烦 但是你会被绕的很晕 一步步来
class CustomTransitionAnimator: UIPercentDrivenInteractiveTransition {
    // 定义一个在各个协议方法里传递信息的类型
    var transitionContext: UIViewControllerContextTransitioning!
    // 因为这个 动画控制器 需要对 present 和 dismiss 进行判断
    private var isDismiss = false
    // 判断 是否 有手势控制
    private var isInteractive = false
    
    // 后方视图 缩放大小
    var behindViewScale: CGFloat = 0.9
    // 后方视图 透明度
    var behindViewAlpha: CGFloat = 0.5
    
    var distance: CGFloat = 240
    private var tempTransform: CATransform3D!
        lazy var gesture: ScrollViewGestureTecognizer = {
            let gesture = ScrollViewGestureTecognizer(target: self, action: Selector("handlePan:"))
    
            gesture.delegate = self
            return gesture
        }()
//    var gesture: ScrollViewGestureTecognizer!
    var modalViewController: UIViewController?
    
    var contentScrollView: UIScrollView! {
        didSet {
            gesture.scrollView = contentScrollView
        }
    }
    
    @objc func handlePan(recognizer: ScrollViewGestureTecognizer) {
        var location = recognizer.locationInView(modalViewController!.view.window)
        location = CGPointApplyAffineTransform(location, CGAffineTransformInvert(recognizer.view!.transform))
        
        var velocity = recognizer.velocityInView(modalViewController!.view.window)
        velocity = CGPointApplyAffineTransform(velocity, CGAffineTransformInvert(recognizer.view!.transform))
        
        if recognizer.state == UIGestureRecognizerState.Began {
            isInteractive = true
            
            panLocationStart = location.y
            modalViewController!.dismissViewControllerAnimated(true, completion: nil)
        } else if recognizer.state == UIGestureRecognizerState.Changed {
            let animationRatio = ((location.y - panLocationStart) + distance) / CGRectGetHeight(modalViewController!.view.bounds)
            
            updateInteractiveTransition(animationRatio)
        } else if recognizer.state == UIGestureRecognizerState.Ended {
            let velocityForSelectedDirtection = velocity.y
            
            if velocityForSelectedDirtection > 100 {
                finishInteractiveTransition()
            } else if velocityForSelectedDirtection < -100 {
                finishInteractiveTransition()
            } else {
                cancelInteractiveTransition()
            }
            isInteractive = false
        }
    }
    
    init(modal: UIViewController) {
        super.init()
        modalViewController = modal
        
//        gesture = ScrollViewGestureTecognizer(target: self, action: Selector("handlePan:"))
//        
//        gesture.delegate = self
        
        modalViewController!.view.addGestureRecognizer(gesture)
    }
    
    var panLocationStart: CGFloat!
}

// MARK: - UIViewControllerTransitioningDelegate
// Step 1: 实现 UIViewControllerTransitioningDelegate
extension CustomTransitionAnimator: UIViewControllerTransitioningDelegate {
    // 说明一下  这里 要返回一个 UIViewControllerAnimatedTransitioning 类型的 对象
    // 这个对象的作用是 是实现一个动画的详细细节
    // 因为 UIViewControllerAnimatedTransitioning 是 Protocol 两种选择 一种是 自己定义个 Class 一种就是 self 实现这个协议
    // 现在 Step 2: 在 self 里面实现这个
    
    // 以下两个方法 只要 return self 是因为 UIViewControllerAnimatedTransitioning 这个里面的实现 会通过 Step 2: 来实现
    // 在presentViewController的时候自动调用
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isDismiss = false
        return self
    }
    
    // 在dismisViewController的时候自动调用
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isDismiss = true
        return self
    }
    
    
    // 这两个是 百分比动画
    func interactionControllerForPresentation(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
    
    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if isInteractive {
            isDismiss = true
            return self
        } else {
            return nil
        }
    }
}

// MARK: - UIViewControllerAnimatedTransitioning
// Step 2: 实现 转场动画的细节 重点就是这个 !!!!!!!!!!!
extension CustomTransitionAnimator: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        // 提取变量 transitionDuration
        return 0.3
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard !isInteractive else {
            debugPrint("手势交互呢~~~~")
            return
        }
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        
        let containerView = transitionContext.containerView()!
        
        let containerViewHeight = CGRectGetHeight(containerView.bounds)
        let containerViewWidth = CGRectGetWidth(containerView.bounds)
        
        
        if !isDismiss {
            
            /**
            *  这部分是 present 的动画 实现
            */
            
            toViewController.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            containerView.addSubview(toViewController.view)
            
            // 变量
            let startRect = CGRect(x: 0, y: containerViewHeight, width: containerViewWidth, height: containerViewHeight - distance)
            
            let transformedPoint = CGPointApplyAffineTransform(startRect.origin, toViewController.view.transform)
            toViewController.view.frame = CGRect(x: transformedPoint.x, y: transformedPoint.y, width: startRect.width, height: startRect.height)
            
            // toViewController.modalPresentationStyle == UIModalPresentationCustom
            //            fromViewController.beginAppearanceTransition(false, animated: true)
            
            
            // 动画开始 这里可以用 pop 来替换
            let duration = transitionDuration(transitionContext)
            // 变量
            UIView.animateWithDuration(duration, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                fromViewController.view.alpha = self.behindViewAlpha
                fromViewController.view.transform = CGAffineTransformScale(fromViewController.view.transform, self.behindViewScale, self.behindViewScale)
                toViewController.view.frame = CGRect(x: 0, y: self.distance, width: toViewController.view.frame.width, height: toViewController.view.frame.height)
                
                }, completion: { (finished) -> Void in
                    // toViewController.modalPresentationStyle == UIModalPresentationCustom
                    fromViewController.endAppearanceTransition()
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            })
        } else {
            
            /**
            *  这部分是 dismiss 的动画 实现
            */
            
            containerView.bringSubviewToFront(fromViewController.view)
            toViewController.view.alpha = behindViewAlpha
            var endRect = CGRect(x: 0, y: fromViewController.view.bounds.height, width: fromViewController.view.bounds.width, height: fromViewController.view.bounds.height - distance)
            
            let transformedPoint = CGPointApplyAffineTransform(endRect.origin, fromViewController.view.transform)
            endRect = CGRect(x: transformedPoint.x, y: UIScreen.mainScreen().bounds.size.height, width: endRect.size.width, height: endRect.size.height)
            
            toViewController.beginAppearanceTransition(true, animated: true)
            let duration = transitionDuration(transitionContext)
            UIView.animateWithDuration(duration, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                
                let scale: CGFloat = CGFloat(1.0) / self.behindViewScale
                toViewController.view.layer.transform = CATransform3DScale(toViewController.view.layer.transform, scale, scale, 1)
                toViewController.view.alpha = 1.0
                fromViewController.view.frame = endRect
                
                }, completion: { (finished) -> Void in
                    toViewController.endAppearanceTransition()
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            })
        }
    }
    
    // 动画结束
    func animationEnded(transitionCompleted: Bool) {
        isInteractive = false;
        //        for subview in transitionContext.containerView()!.subviews {
        //            debugPrint(subview)
        //        }
        transitionContext = nil;
    }
}

// 这个 Protocol 是 UIPercentDrivenInteractiveTransition 继承的
// MARK: - UIViewControllerInteractiveTransitioning
extension CustomTransitionAnimator {
    // 所有 手势动画的 第一步!!!!!!!
    override func startInteractiveTransition(transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        
        tempTransform = toViewController.view.layer.transform
        
        toViewController.view.alpha = behindViewAlpha
        
        transitionContext.containerView()!.bringSubviewToFront(fromViewController.view)
    }
}

// override 这里的方式 是手势驱动 交互动画的
extension CustomTransitionAnimator {
    override func updateInteractiveTransition(percentComplete: CGFloat) {
        
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        
        let sacle = 1 + (((1 / self.behindViewScale) - 1) * percentComplete)
        let transform = CATransform3DMakeScale(sacle, sacle, 1)
        toViewController.view.layer.transform = CATransform3DConcat(tempTransform, transform)
        toViewController.view.alpha = behindViewAlpha + sacle - 1.0
        
        var updateRect = CGRect(x: 0, y: fromViewController.view.bounds.height * percentComplete, width: fromViewController.view.bounds.width, height: fromViewController.view.bounds.height)
        
        if isnan(updateRect.origin.x) || isinf(updateRect.origin.x) {
            updateRect.origin.x = 0
        }
        
        if isnan(updateRect.origin.y) || isinf(updateRect.origin.y) {
            updateRect.origin.y = 0
        }
        
        let transformedPoint = CGPointApplyAffineTransform(updateRect.origin, fromViewController.view.transform)
        updateRect = CGRect(x: transformedPoint.x, y: transformedPoint.y, width: updateRect.width, height: updateRect.height)
        fromViewController.view.frame = updateRect
    }
    
    override func cancelInteractiveTransition() {
        
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        
        UIView.animateWithDuration(0.4, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            
            toViewController.view.layer.transform = self.tempTransform
            toViewController.view.alpha = self.behindViewAlpha
            fromViewController.view.frame = CGRect(x: 0, y: self.distance, width: fromViewController.view.frame.width, height: fromViewController.view.frame.height)
            
            }) { (finished) -> Void in
                self.transitionContext.completeTransition(false)
        }
    }
    
    override func finishInteractiveTransition() {
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        
        var endRect = CGRect(x: 0, y: fromViewController.view.bounds.height, width: fromViewController.view.bounds.width, height: fromViewController.view.bounds.height)
        
        let transformePoint = CGPointApplyAffineTransform(endRect.origin, fromViewController.view.transform)
        
        endRect = CGRect(x: transformePoint.x, y: UIScreen.mainScreen().bounds.size.height, width: endRect.width, height: endRect.height)
        toViewController.beginAppearanceTransition(true, animated: true)
        let duration = transitionDuration(transitionContext)
        UIView.animateWithDuration(duration, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            
            let scale = 1 / self.behindViewScale
            toViewController.view.layer.transform = CATransform3DScale(self.tempTransform, scale, scale, 1)
            toViewController.view.alpha = 1.0
            fromViewController.view.frame = endRect
            }) { (finished) -> Void in
                toViewController.endAppearanceTransition()
                self.transitionContext.completeTransition(true)
        }
    }
}

extension CustomTransitionAnimator {
    
}

extension CustomTransitionAnimator: UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

class ScrollViewGestureTecognizer: UIPanGestureRecognizer {
    var isFail: Bool?
    var scrollView: UIScrollView!
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesMoved(touches, withEvent: event)
        
        guard let _ = scrollView else {
            return
        }
        
        guard state != UIGestureRecognizerState.Failed else {
            return
        }
        
        let nowPoint = touches.first!.locationInView(view)
        let previousPoint = touches.first!.previousLocationInView(view)
        
        if let _ = isFail {
            if isFail! {
                state = UIGestureRecognizerState.Failed
            }
            return
        }
        
        let topVierticalOffset = -scrollView.contentInset.top
        
        if nowPoint.y > previousPoint.y && scrollView.contentOffset.y <= topVierticalOffset {
            isFail = false
        } else if scrollView.contentOffset.y >= topVierticalOffset {
            isFail = true
        } else {
            isFail = false
        }
    }
    
    override func reset() {
        super.reset()
        isFail = nil
    }
}






