package im.mobius.mobilebenchmark
{
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.MouseEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.system.System;
    import flash.utils.setTimeout;
    
    import im.mobius.debug.Debugger;
    import im.mobius.view.RawComponent;
    
    /**
     * IO性能测试基准 
     * @author mobiuschen
     * 
     */    
    public class IOBenchMark extends Sprite
    {
        public function IOBenchMark()
        {
            super();
            
            initView();
        }
        
        
        public var ts:Number;
        
        
        public function initView():void
        {
            var btns:Vector.<Sprite> = new Vector.<Sprite>();
            var btn:Sprite;
            
            btn = RawComponent.createBtn("Sync IO");
            btn.addEventListener(MouseEvent.CLICK, onClickSyncIO);
            btns.push(btn);
            
            btn = RawComponent.createBtn("Async IO");
            btn.addEventListener(MouseEvent.CLICK, onClickAsyncIO);
            btns.push(btn);
            
            for(var i:int = 0, n:int = btns.length; i < n; i++)
            {
                btn = btns[i];
                btn.x = 10;
                btn.y = i * 50 + 120;
                addChild(btn);
            }
        }
        
        
        private function testSyncIO():void
        {
            ts = new Date().time;
            const assetsPah:String = "app:/happyfarm/module/ui/allcrops";
            var fs:FileStream = new FileStream();
            var dir:File = new File(assetsPah);
            var arr:Array/*of File*/ = dir.getDirectoryListing(); 
            var n:int = arr.length;
            var file:File;
            
            Debugger.log("文件数量", n);
            
            var newDate:Number;
            var preBatchTS:Number = ts;
            
            for(var i:int = 0; i < n; i++)
            {
                file = arr[i];
                if(file.isDirectory)
                    continue;
                fs.open(file, FileMode.READ);
                //trace(fs.bytesAvailable);
                fs.close();
                
                if(i % 100 == 0)
                {
                    newDate = new Date().time;
                    Debugger.log(((newDate - preBatchTS)*0.001).toFixed(3) + "s");
                    preBatchTS = newDate;
                }
            }
            Debugger.log("总耗时", ((new Date().time - ts)*0.001).toFixed(3) + "s");
            
            //把所有信息都打印出来
            //QFAConsole.printToScreen();
            
            System.gc();
        }
        
        
        private function testAsyncIO():void
        {
            ts = new Date().time;
            const assetsPah:String = "app:/happyfarm/module/ui/allcrops";
            var dir:File = new File(assetsPah);
            var arr:Array/*of File*/ = dir.getDirectoryListing(); 
            var count:int = arr.length;
            var soloTS:Number;
            
            loadNext();
            
            function loadNext():void
            {
                if(--count < 0)
                {
                    Debugger.log("总耗时", ((new Date().time - ts)*0.001).toFixed(3) + "s");
                    //把所有信息都打印出来
                    //QFAConsole.printToScreen();
                    System.gc();
                    return;
                }
                var file:File = arr[count];
                if(file.isDirectory)
                    setTimeout(loadNext, 5);
                
                var fs:FileStream = new FileStream();
                fs.addEventListener(Event.COMPLETE, onOpenComplete);
                fs.addEventListener(IOErrorEvent.IO_ERROR, onOpenComplete);
                fs.openAsync(file, FileMode.READ);
            }
            
            
            function onOpenComplete(evt:Event):void
            {
                var fs:FileStream = evt.currentTarget as FileStream;
                fs.removeEventListener(Event.COMPLETE, onOpenComplete);
                fs.removeEventListener(IOErrorEvent.IO_ERROR, onOpenComplete);
                
                if(count % 100 == 0)
                {
                    Debugger.log(
                        "Async IO:", 
                        "count="+count, 
                        "bytesAvailable="+fs.bytesAvailable,
                        ((new Date().time - ts) * 0.001).toFixed(3) + "s"
                    );
                    
                    //把所有信息都打印出来
                }
                fs.close();
                fs = null;
                
                loadNext();
            }
        }
        
        
        private function onClickAsyncIO(evt:MouseEvent):void
        {
            testAsyncIO();
        }
        
        
        private function onClickSyncIO(evt:MouseEvent):void
        {
            testSyncIO();
        }
    }
}