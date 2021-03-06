package im.mobius.vulcanus.utils
{
    import flash.display.DisplayObject;
    import flash.display.Stage;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;


    /**
     * Resulotion Utils.
     * 
     * @author mobiuschen
     * 
     */    
    public class ResolutionUtils
    {
        
        static public const IPHONE4_RECT:Rectangle = new Rectangle(0, 0, 960, 640);
        
        static public const IPAD2_RECT:Rectangle = new Rectangle(0, 0, 1024, 768);
        
        static public const IPAD3_RECT:Rectangle = new Rectangle(0, 0, 2048, 1536);
        
        static public var DEF_SCREEN_RECT:Rectangle = IPHONE4_RECT;
        
        
        
        /**
         * 当前屏幕分辨率相对于iphone4分辨率的比例 
         */    
        static public var SCALE_COMPARED_TO_IP4:ScaleList;
        
        /**
         * 当前屏幕分辨率相对于ipad分辨率的比例 
         */    
        static public var SCALE_COMPARED_TO_IPAD:ScaleList;
        
        
        static private var _actScreenRect:Rectangle;
        
        static public var stage:Stage;
        
        /**
         * 当前屏幕的Rectangle 
         */
        static public function get SCREEN_RECT():Rectangle
        {
            if(stage == null)
                return new Rectangle();
            
            if(_actScreenRect == null)
            {
                _actScreenRect = stage.fullScreenSourceRect;
                SCALE_COMPARED_TO_IP4 = ResolutionUtils.getRectScale(IPHONE4_RECT, _actScreenRect);
                SCALE_COMPARED_TO_IPAD = ResolutionUtils.getRectScale(IPAD2_RECT, _actScreenRect);
            }
            
            return _actScreenRect;
        }
        
        
        
        /**
         * 将设计图中的某个位置点通过自适应屏幕之后，在真实屏幕上的位置 
         * @param expectPoint
         * @param expectRect
         * @return 
         * 
         */    
        static public function translatePoint(expectPoint:Point, expectRect:Rectangle):Point
        {
            var vS:Number = SCREEN_RECT.height / expectRect.height;
            var hS:Number = SCREEN_RECT.width / expectRect.width;
            var newP:Point = new Point(expectPoint.x * hS, expectPoint.y * vS);
            return newP;
        }
        
        
        static public function multiAdapts(views:Vector.<DisplayObject>,
                                           posMode:int, sizeMode:int,
                                           expectRect:Rectangle = null,
                                           actualRect:Rectangle = null):Vector.<Matrix>
        {
            if(views == null)
            {
                throw new ArgumentError("ArgumentError");
                return;
            }
            var mtxs:Vector.<Matrix> = new Vector.<Matrix>();
            if(views.length == 0)
                return mtxs;
            for(var i:int = 0, n:int = views.length; i < n; i++)
            {
                mtxs.push(adapts(views[i], posMode, sizeMode, expectRect, actualRect));
            }
            return mtxs;
        }
        
        
        /**
         * 将某个ui元素屏幕自适应。
         * 
         * @param view 自适应对象
         * @param posMode 位置自适应模式
         * @param sizeMode 尺寸自适应模式
         * @param expectRect ui元素是根据哪种屏幕尺寸绘制的
         * @param actualRect 实际屏幕尺寸，这个参数默认不用修改，会默认使用当前屏幕尺寸。
         * @return 
         * 
         */    
        static public function adapts(view:DisplayObject,
                                      posMode:int, sizeMode:int,
                                      expectRect:Rectangle = null,
                                      actualRect:Rectangle = null):Matrix
        {
            var mtx:Matrix;
            
            mtx = adaptSize(view, sizeMode, expectRect, actualRect);
            adaptPosition(view, posMode, expectRect, actualRect);
            
            return mtx;
        }
        
        
        /**
         * 
         * 位置自适应. 
         * 
         * @param view
         * @param mode
         * @param expectRect
         * @param actualRect
         * @return 返回view适应前的transform.matrix
         * 
         */    
        static public function adaptPosition(view:DisplayObject, mode:int,
                                             expectRect:Rectangle = null,
                                             actualRect:Rectangle = null):Matrix
        {
            if(view == null)
            {
                throw new ArgumentError("ArgumentError");
                return null;
            }
            
            if(expectRect == null)
                expectRect = DEF_SCREEN_RECT;
            
            if(actualRect == null)
                actualRect = SCREEN_RECT;
            
            var vGap:Number = 0;
            var hGap:Number = 0;
            var gap:Number = 0;
            
            var mtx:Matrix = view.transform.matrix;
            
            
            //底部
            if(mode > 6)
            {
                vGap = (expectRect.bottom - view.y) / expectRect.bottom;
                gap = expectRect.bottom - view.y;
                view.y = actualRect.bottom - gap;
            }
                //中间
            else if(mode > 3)
            {
                view.y = view.y * actualRect.height / expectRect.height;
            }
            
            //中间
            if([2,5,8].indexOf(mode) > -1)
            {
                view.x = view.x * actualRect.width / expectRect.width;
            }
                //右边
            else if([3, 6, 9].indexOf(mode) > -1)
            {
                hGap = (expectRect.right - view.x) / expectRect.right;
                gap = expectRect.right - view.x;
                view.x  = actualRect.right - gap;
            }
            
            return mtx;
        }
        
        
        /**
         * 尺寸自适应
         *  
         * @param view
         * @param mode
         * @param expectRect
         * @param actualRect
         * @return 返回view适应前的transform.matrix
         * 
         */    
        static public function adaptSize(view:DisplayObject, mode:int,
                                         expectRect:Rectangle = null,
                                         actualRect:Rectangle = null):Matrix
        {
            if(view == null)
            {
                throw new ArgumentError("ArgumentError");
                return null;
            }
            
            if(expectRect == null)
                expectRect = DEF_SCREEN_RECT;
            
            if(actualRect == null)
                actualRect = SCREEN_RECT;
            
            var mtx:Matrix = view.transform.matrix;
            
            if(mode == SizeAdaptiveMode.CUSTOM)
                return mtx;
            
            var vS:Number = actualRect.height / expectRect.height;
            var hS:Number = actualRect.width / expectRect.width;
            var dict:Object ={}
            dict[SizeAdaptiveMode.HORIZONTAL] = hS;
            dict[SizeAdaptiveMode.VERTICAL] = vS;
            dict[SizeAdaptiveMode.MAX] = vS < hS ? hS : vS;;
            dict[SizeAdaptiveMode.MIN] = vS > hS ? hS : vS;;
            
            view.scaleX *= dict[mode];
            view.scaleY *= dict[mode];
            
            return mtx;
        }
        
        
        /**
         * rect2相对rect1的缩放数据. 
         * @param rect1
         * @param rect2
         * @return {vScale, hScale, maxScale, minScale}
         * 
         */    
        static public function getRectScale(rect1:Rectangle, rect2:Rectangle):ScaleList
        {
            var sl:ScaleList = new ScaleList();
            sl.vScale = rect2.height / rect1.height;
            sl.hScale = rect2.width / rect1.width;
            sl.maxScale = sl.vScale > sl.hScale ? sl.vScale : sl.hScale;
            sl.minScale = sl.vScale < sl.hScale ? sl.vScale : sl.hScale;
            return sl;
        }
        
        
        public function ResolutionUtils()
        {
        }
    }
}



class ScaleList extends Object
{
    public var maxScale:Number = 0;
    public var minScale:Number = 0;
    public var vScale:Number = 0;
    public var hScale:Number = 0;
    
    public function toString():String
    {
        var arr:Array = [
            "[ScaleList]:",
            "maxScale =", maxScale.toFixed(2),
            "minScale =", minScale.toFixed(2),
            "vScale =", vScale.toFixed(2),
            "hScale =", hScale.toFixed(2),
        ];
        return arr.join(" ");
    }
}