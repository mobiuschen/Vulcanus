package im.mobius.vulcanus
{
    import flash.display.DisplayObject;
    import flash.display.Shape;
    import flash.geom.Rectangle;
    
    import asunit.framework.Assert;

    public class QuadTree
    {
        private var _topLeft:QuadTree = null;
        private var _topRight:QuadTree = null;
        private var _bottomLeft:QuadTree = null;
        private var _bottomRight:QuadTree = null;
        
        
        private var _halfW:Number = 0;
        private var _halfH:Number = 0;
        
        private var _area:Rectangle = null;
        
        private var _minGridSize:Number = 0;
        
        private var _chidren:Vector.<DisplayObject>;
        
        private var _maxLevel:int = 0;
        
        /**
         *  
         * @param areaRect
         * @param minGridSize 利用最小Grid尺寸来限制检测深度
         * 
         */
        public function QuadTree(areaRect:Rectangle, minGridSize:Number, maxLevel:int)
        {
            _area = areaRect.clone();
            _minGridSize = minGridSize;
            _maxLevel = maxLevel;
            
            init();
        }
        
        
        
        public function reset(allObjs:Vector.<DisplayObject>):void
        {
            Assert.assertTrue(allObjs != null);
            var obj:DisplayObject;
            
            for each(obj in allObjs)
                insert(obj);
        }
        
        
        public function insert(obj:DisplayObject):Vector.<Vector.<int>>
        {
            /*
                1, 2,
                3, 4
                分别标识左上, 右上, 左下, 右下.
                0, 当前树
            */
            var result:Vector.<Vector.<int>>;
            
            //To do...
            //暂时不考虑坐标点不在左上角的情况
            var bounds:Rectangle = new Rectangle(obj.x, obj.y, obj.width, obj.height);
            
            //如果当物体区域大于(即覆盖)_area, 则不加入任何子四叉树, 直接加入当前树.
            //或者当没有子树的时候, 也直接加入当前树.
            if(bounds.containsRect(_area) || _topLeft == null)
            {
                _chidren.push(obj);
                return new <Vector.<int>>[new <int>[0]];
            }
            
            result = new Vector.<Vector.<int>>();
            var childrenTrees:Vector.<QuadTree> = new <QuadTree>[
                _topLeft, _topRight, _bottomLeft, _bottomRight
            ];
            var flg:Boolean = false;
            var posQueue:Vector.<Vector.<int>>;
            for(var i:int = 0, n:int = childrenTrees.length; i < n; i++)
            {
                var childTree:QuadTree = childrenTrees[i];
                //只要与子区域有重叠, 就考虑加入相应的子区域
                //注意, 一个obj可能加入多个子四叉树.
                if(childTree != null && childTree.getArea().intersects(bounds))
                {
                    posQueue = childTree.insert(obj);
                    for each(var vec:Vector.<int> in posQueue)
                    {
                        vec.unshift(i + 1);
                    }
                    result = result.concat(posQueue);
                    flg = true;
                }
            }
            return result;
        }
        
        
        
        public function retriveByRect(rect:Rectangle):Vector.<DisplayObject>
        {
            var result:Vector.<DisplayObject> = new Vector.<DisplayObject>();
            
            //区域没有重叠, 返回空Vector.
            if(!_area.intersects(rect))
                return result;
            
            var childrenTrees:Vector.<QuadTree> = 
                new <QuadTree>[
                    _topLeft, _topRight, _bottomLeft, _bottomRight
                ];
            for each(var qt:QuadTree in childrenTrees)
            {
                if(qt == null)
                    continue;
                result = result.concat(qt.retriveByRect(rect));
            }
                
            result = result.concat(_chidren);
            return result;
        }
        
        
        /**
         * 清理掉所有children, 但是区域划分不变. 
         * 
         */        
        public function clear():void
        {
            if(_topLeft != null)
            {
                _topLeft.clear();
                _topRight.clear();
                _bottomLeft.clear();
                _bottomRight.clear();
            }
            
            _chidren = new Vector.<DisplayObject>();
        }

        
        
        public function getArea():Rectangle
        {
            return _area;
        }
        
        
        public function drawIt(shape:Shape, drawBg:Boolean = false):void
        {
            if(shape == null)
                return;
            
            if(drawBg)
            {
                shape.graphics.beginFill(0xAAAAAA);
                shape.graphics.drawRect(_area.x, _area.y, _area.width, _area.height);
                shape.graphics.endFill();
            }
            
            
            shape.graphics.lineStyle(1, 0xff0000);
            shape.graphics.drawRect(_area.x, _area.y, _area.width, _area.height);
            
            shape.graphics.lineStyle(1, 0, 0);  
            shape.graphics.beginFill(0x00ff00, 0.2);
            for each(var obj:DisplayObject in _chidren)
            shape.graphics.drawRect(obj.x, obj.y, obj.width, obj.height);
            shape.graphics.endFill();
            
            if(_topLeft == null)
                return;
                      
            shape.graphics.moveTo(0, _halfH);
            shape.graphics.lineTo(_area.width, _halfH);            
            shape.graphics.moveTo(_halfW, 0);
            shape.graphics.lineTo(_halfW, _area.height);
            
            _topLeft.drawIt(shape);
            _topRight.drawIt(shape);
            _bottomLeft.drawIt(shape);
            _bottomRight.drawIt(shape);
        }
        
        
        private function init():void
        {
            _chidren = new Vector.<DisplayObject>();
            
            _halfW = _area.width >> 1;
            _halfH = _area.height >> 1;
            
            if(_halfW < _minGridSize || _halfH < _minGridSize || _maxLevel <= 0)
                return;
            
            _topLeft = new QuadTree(new Rectangle(_area.x, _area.y, _halfW, _halfH), _minGridSize, _maxLevel - 1);
            _topRight = new QuadTree(new Rectangle(_area.x + _halfW, _area.y, _halfW, _halfH), _minGridSize, _maxLevel - 1);
            _bottomLeft = new QuadTree(new Rectangle(_area.x, _area.y + _halfH, _halfW, _halfH), _minGridSize, _maxLevel - 1);
            _bottomRight = new QuadTree(new Rectangle(_area.x + _halfW, _area.y + _halfH, _halfW, _halfH), _minGridSize, _maxLevel - 1);
        }
        
    }
}