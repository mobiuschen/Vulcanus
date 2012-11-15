package im.mobius
{
    import flash.display.DisplayObject;
    import flash.filters.GlowFilter;
    import flash.geom.Rectangle;

    public class QuadTreeCollisionDetection
    {
        private var _quadTree1:QuadTree;
        private var _quadTree2:QuadTree;
        
        private var _camp1:Vector.<DisplayObject>;
        private var _camp2:Vector.<DisplayObject>;
        
        private var _glowFilter:GlowFilter;
        
        public function QuadTreeCollisionDetection()
        {
        }
        
        
        private function init():void
        {
            _glowFilter = new GlowFilter();
        }
        
        
        public function initCamps(area:Rectangle, minGirdSize:Number, maxLevel:int, 
                                  camp1:Vector.<DisplayObject>, camp2:Vector.<DisplayObject>):void
        {
            if(_quadTree1 != null)
                _quadTree1.clear();
            
            if(_quadTree2 != null)
                _quadTree2.clear();
            
            _quadTree1 = new QuadTree(area, minGirdSize, maxLevel);
            _quadTree2 = new QuadTree(area, minGirdSize, maxLevel);
            
            _camp1 = camp1;
            _camp2 = camp2;
        }
        
        
        public function detectCollision():void
        {
            _quadTree1.reset(_camp1);
            _quadTree2.reset(_camp2);
            
            
            for each(var obj2:DisplayObject in _camp2)
                obj2.filters = [];
            
            for each(var obj1:DisplayObject in _camp1)
            {
                var bounds:Rectangle = obj1.getBounds(null);
                
                var collisions:Vector.<DisplayObject> = _quadTree2.retriveByRect(bounds);
                for(obj2 in collisions)
                    obj2.filters = [_glowFilter];
            }
        }
        
    }
}