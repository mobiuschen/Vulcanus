package im.mobius.vulcanus.view
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;
    
    public class BmpArea extends Sprite
    {
        private var _container:Sprite;
        
        private var _bmp:Bitmap;
        
        private var _bpd:BitmapData;
        
        /**
         * 背景的区域 
         */        
        private var _bgByteArray:ByteArray;
        
        private var _rect:Rectangle;
        
        /**
         * 相对于舞台的帧率的减慢倍数.
         */        
        private var _slowMutiple:int = 1;
        
        /**
         * 
         */        
        private var _frameCount:int = 0;
        
        public function BmpArea(width:Number, height:Number, slowMutiple:int = 1)
        {
            super();
            
            mouseChildren = false;
            
            _rect = new Rectangle(0, 0, width, height);
            _container = new Sprite();
            _bpd = new BitmapData(width, height, true, 0x88000000);
            _bgByteArray = _bpd.getPixels(_rect);
            _bgByteArray.position = 0;
            _bmp = new Bitmap(_bpd);
            super.addChild(_bmp);
            
            _slowMutiple = slowMutiple;
            
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }
        
        
        private function render():void
        {
            _bpd.lock();
            _bpd.setPixels(_rect, _bgByteArray);
            _bpd.draw(_container, null);
            _bpd.unlock();
            _bgByteArray.position = 0;
        }
        
        
        private function onEnterFrame(evt:Event):void
        {
            if(++_frameCount < _slowMutiple)
                return;
            
            _frameCount = 0;
            render();
        }
        
        
        /**
         * 设置BmpArea的帧率.该帧率不能大于stage的帧率.
         * @param value
         * 
         */        
        public function setSlowDownMultiple(value:int):void
        {
            _slowMutiple = value;
            _frameCount = 1;
        }
        
        
        override public function addChild(child:DisplayObject):DisplayObject
        {
            return _container.addChild(child);
        }
        
        
        override public function addChildAt(child:DisplayObject, index:int):DisplayObject
        {
            return _container.addChildAt(child, index);
        }
        
        
        override public function removeChild(child:DisplayObject):DisplayObject
        {
            return _container.removeChild(child);
        }
        
        
        override public function removeChildAt(index:int):DisplayObject
        {
            return _container.removeChildAt(index);
        }
        
        override public function removeChildren(beginIndex:int=0, endIndex:int=int.MAX_VALUE):void
        {
            _container.removeChildren(beginIndex, endIndex);
        }
        
        override public function contains(child:DisplayObject):Boolean
        {
            return _container.contains(child);
        }
        
        
        override public function getChildAt(index:int):DisplayObject
        {
            return _container.getChildAt(index);
        }
        
        
        override public function getChildByName(name:String):DisplayObject
        {
            return _container.getChildByName(name);
        }
        
        
        override public function getChildIndex(child:DisplayObject):int
        {
            return _container.getChildIndex(child);
        }
        
        
        override public function setChildIndex(child:DisplayObject, index:int):void
        {
            _container.setChildIndex(child, index);
        }
        
        
        override public function get numChildren():int
        {
            return _container.numChildren;
        }
    }
}