package im.mobius.mobilebenchmark
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.Timer;
    
    import im.mobius.ui.RollingPlanetUI;
    import im.mobius.view.RawComponent;
    
    public class RenderBenchMark extends Sprite
    {
     
        /**
         * 取样间隔，单位ms 
         */        
        static private const SAMPLE_INTERVAL:int = 20;
        
        static private const EVT_CACHE_COMPLETE:String = "EvtCacheComplete";
        
        /**
         * 动画类 
         */        
        static private const UI_CLASS:Class = RollingPlanetUI;
        
        static private const NUM:int = 100;
        
        public function RenderBenchMark()
        {
            super();
            
            addEventListener(EVT_CACHE_COMPLETE, onCacheComplete);
            addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
            cacheAnimation(new UI_CLASS);
        }
        
        
        
        
        private var _btnLayer:Sprite;
        
        private var _renderLayer:Sprite
        
        
        private var bmpFrames:Vector.<BitmapFrame>;
        
        
        
        public function initView():void
        {
            _renderLayer = new Sprite();
            _btnLayer = new Sprite();
            var btns:Vector.<Sprite> = new Vector.<Sprite>();
            var btn:Sprite;
            
            btn = RawComponent.createBtn("矢量");
            btn.addEventListener(MouseEvent.CLICK, onClickVectorRender);
            btns.push(btn);
            
            btn = RawComponent.createBtn("BitmapAnimation");
            btn.addEventListener(MouseEvent.CLICK, onClickBimapAnimation);
            btns.push(btn);
            
            btn = RawComponent.createBtn("Copypixels");
            //btn.addEventListener(MouseEvent.CLICK, onClickAsyncIO);
            btns.push(btn);
            
            btn = RawComponent.createBtn("Starling");
            //btn.addEventListener(MouseEvent.CLICK, onClickAsyncIO);
            btns.push(btn);
            
            btn = RawComponent.createBtn("ND2D");
            //btn.addEventListener(MouseEvent.CLICK, onClickAsyncIO);
            btns.push(btn);
            
            for(var i:int = 0, n:int = btns.length; i < n; i++)
            {
                btn = btns[i];
                btn.x = 10;
                btn.y = i * 50 + 120;
                _btnLayer.addChild(btn);
            }
            
            
            addChild(_renderLayer);
            addChild(_btnLayer);
        }
        
        
        private function cacheAnimation(mc:MovieClip):void
        {
            if(mc == null)
                return;
            
            bmpFrames = new Vector.<BitmapFrame>();
            
            var count:int = mc.totalFrames;
            var timer:Timer = new Timer(SAMPLE_INTERVAL, 0);
            timer.addEventListener(TimerEvent.TIMER, onTimer);
            mc.addEventListener(Event.ENTER_FRAME, onEnterFrame);
            mc.gotoAndStop(1);
            mc.play();
            timer.start();
            
            var mtx:Matrix = new Matrix();
            
            function onTimer(evt:Event):void
            {
                trace("onTimer");
                var rect:Rectangle = mc.getBounds(mc);
                mtx.tx = -rect.x;
                mtx.ty = -rect.y;
                //var bpd:BitmapData = new BitmapData(rect.width, rect.height, false, 0xff0000);
                var bpd:BitmapData = new BitmapData(rect.width, rect.height, true, 0x00000000);
                bpd.draw(mc, mtx);
                var bf:BitmapFrame = new BitmapFrame();
                bf.pos = new Point(rect.x, rect.y);
                bf.bitmapData = bpd;
                bmpFrames.push(bf);
            }
            
            function onEnterFrame(evt:Event):void
            {
                trace("onEnterFrame", count);
                if(--count > 0)
                    return;
                
                mc.stop();
                mc.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
                timer.removeEventListener(TimerEvent.TIMER, onTimer);
                
                dispatchEvent(new Event(EVT_CACHE_COMPLETE));
            }
        }
        
        
        private function onClickVectorRender(evt:MouseEvent):void
        {
            removeChild(_btnLayer);
            var mc:MovieClip;
            for(var i:int = 0; i < NUM; i++)
            {
                mc = new UI_CLASS();
                mc.x = Math.random() * stage.fullScreenWidth;
                mc.y = Math.random() * stage.fullScreenHeight;
                _renderLayer.addChild(mc);
            }
        }
        
        
        private function onClickBimapAnimation(evt:MouseEvent):void
        {
            removeChild(_btnLayer);
            var bmp:Bitmap = new Bitmap();
            _renderLayer.addChild(bmp);
            var timer:Timer = new Timer(SAMPLE_INTERVAL, 0);
            timer.addEventListener(TimerEvent.TIMER, onTimer);
            timer.start();
            
            var idx:int = 0;
            
            function onTimer(evt:TimerEvent):void
            {
                if(++idx >= bmpFrames.length)
                    idx = 0;
                bmp.bitmapData = bmpFrames[idx].bitmapData;
                bmp.x = bmpFrames[idx].pos.x;
                bmp.y = bmpFrames[idx].pos.y;
            }
        }
        
        
        
        private function onCacheComplete(evt:Event):void
        {
            initView();
        }
        
        
        private function onDoubleClick(evt:MouseEvent):void
        {
            if(!contains(_btnLayer)) 
                addChild(_btnLayer);
        }
    }
}



import flash.display.BitmapData;
import flash.geom.Point;


class BitmapFrame
{
    public var pos:Point;
    
    public var bitmapData:BitmapData;
}