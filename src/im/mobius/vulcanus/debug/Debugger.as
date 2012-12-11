package im.mobius.vulcanus.debug
{
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.system.Capabilities;
	import flash.utils.setTimeout;
	
	import asunit.framework.Assert;
	

    /**
     * 
     * @author mobiuschen
     * 
     */    
	public class Debugger extends EventDispatcher
	{
        
        static public const SAVE_PATH:String = "im.mobius.debugger/";
        
        /**
         * Debugger是否可用的开关 
         */
        static public var ENABLED:Boolean = true;
        
        /**
         * To do...这里应该使用服务器时间
         */        
        static private var _fileName:String;
        
        
        static private var _logBatch:LogBatch;
        
        static private var _ui:IConsoleWindow;
        
        static private var _stage:Stage;
        
        
        
        public static function init(stage:Stage, serverTime:Number, ui:IConsoleWindow):void
        {
            _fileName =  serverTime + ".log";
            _stage = stage;
            _logBatch = new LogBatch();
            
            _ui = ui;
            if(_ui != null)
                _ui.setLogBatch(_logBatch);
        }
        
        
        /**
         * 打印Log信息, 增加分类功能.
         *  
         * @param args 如果最后一个参数是LogType枚举的类型, 则会将其记录进该类型的Log. 
         *             否则认为是LogType.MISC类型的Log.
         * 
         * Demo: 
         * Debugger.log("123", "456", LogType.MISC);
         * 
         */
		public static function log(... args):void
		{
            if(!ENABLED)
                return;
            
            var type:String = args[args.length - 1];
            var str:String = args.join(", ");
            if(args.length <= 1 || LogType.ALL_TYPES.indexOf(type) < 0)
            {
                type = LogType.MISC;
                str = args.join(", ");
            }
            else
            {
                str = args.slice(0, args.length - 1).join(", ");
            }
            _logBatch.createLog(type, str);
            
            //更新ui
            if(_ui != null)
                _ui.update();
		}
        
        
        /**
         * 断言.
         * 
         * </p>
         * ENABLED == true, 失败的断言会抛错。
         * ENABLED == false, 失败的断言作为log纪录下来.
         * 
         * @param expr
         * @param errorMsg
         * 
         * @return 返回的是expr的值 
         */        
        static public function assert(expr:Boolean, errorMsg:String = null):Boolean
        {
            if(expr)
                return true;
            
            var error:Error = new Error(errorMsg == null ? "Assert Error." : errorMsg);
            if(ENABLED)
                //Treat ASSERT as ERROR.
                throw new Error(error);
            else if(Capabilities.isDebugger)
                //debugger无法读取Error.getStackTrace()
                log(error.message, error.getStackTrace(), LogType.ASSERT);
            else
                log(error.message, LogType.ASSERT);
            
            return false;
        }
        
            
        /**
         * 将本次进程的所有Log保存到本地。
         * 
         * @param file
         * @return 
         * 
         */        
        static public function save():Boolean
        {
            if(_logBatch == null)
                return false;
            var content:String = LogBatch.serialize(_logBatch).toXMLString();
            var file:File = 
                File.applicationStorageDirectory.resolvePath(SAVE_PATH + _fileName);
            var fs:FileStream = new FileStream();
            fs.open(file, FileMode.WRITE);
            fs.writeUTF(content);
            fs.close();
            return true;
        }
        
        
        /**
         * 从本地加载某个log文件
         * @param file
         * @return 
         * 
         */        
        static public function load(file:File):Boolean
        {
            if(file == null || !file.exists)
                return false;
            
            var fs:FileStream = new FileStream();
            fs.open(file, FileMode.READ);
            var content:String = fs.readUTF();
            var xml:XML;
            var lb:LogBatch;
            try
            {
                xml = new XML(content);
                lb = LogBatch.deserialize(xml);
            }
            catch(err:Error)
            {
                return false;
            }
            
            if(lb == null)
                return false;
            
            //trace(xml.toXMLString());
            
            _logBatch = lb;
            return true;
        }
        
        
        
        /**
         * 将最近一次登录的LogBatch提交到服务器。<br/>
         * To do...如何把这个接口抽象，做成可配置，与业务无关。
         * 
         * @callback 操作完成之后的返回，原型是callback(success:Boolean)，参数success表示成功与否。
         */        
        static public function uploadLastLoginBatch(userInfo:String, callback:Function):void
        {
            const firstSepr:String = "@@";
            const secondarySepr:String = "##";
            
            var file:File = File.applicationStorageDirectory.resolvePath(SAVE_PATH);
            var arr:Array = file.getDirectoryListing();
            if(arr.length == 0)
            {
                if(callback != null)
                    setTimeout(callback, 10, false);
                return;
            }
                
            arr.sort(compare);
            file = arr[arr.length - 1];
            var fs:FileStream = new FileStream();
            
            fs.open(file, FileMode.READ);
            var content:String = fs.readUTF();
            fs.close();
            
            try
            {
                var xml:XML = new XML(content);
                var lb:LogBatch = LogBatch.deserialize(xml);
            }
            catch(error:Error)
            {
                if(callback != null)
                    setTimeout(callback, 10, false);
                return;
            }
            
            var tempArr:Array = [userInfo];
            var allLogs:Vector.<LogEntity> = lb.getAllLogs();
            var l:LogEntity;
            for(var i:int = 0, n:int = allLogs.length; i < n; i++)
            {
                l = allLogs[i];
                tempArr.push(
                    [l.msg, l.type, l.time].join(secondarySepr)
                );
            }
            var requestBody:String = tempArr.join(firstSepr);
            
            
            //To do...上传到服务器
            var cgi:String = "http://nc.qzone.qq.com/cgi-bin/cgi_app_report?i=log";
            var ul:URLLoader = new URLLoader();
            var ur:URLRequest = new URLRequest(cgi);
            ur.data = requestBody;
            ur.method = URLRequestMethod.POST;
            ul.addEventListener(Event.COMPLETE, onResponse);
            ul.addEventListener(IOErrorEvent.IO_ERROR, onResponse);
            ul.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onResponse);
            ul.load(ur);
            
            function onResponse(evt:Event):void
            {
                ul.removeEventListener(Event.COMPLETE, onResponse);
                ul.removeEventListener(IOErrorEvent.IO_ERROR, onResponse);
                ul.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onResponse);
                
                if(callback != null)
                    callback(evt.type == Event.COMPLETE);
            }
                
            //按创建时间，从旧到新排列
            function compare(file1:File, file:File):int
            {
                if(file.creationDate.time < file.creationDate.time)
                    return -1;
                else if(file.creationDate.time > file.creationDate.time)
                    return 1;
                return 0;
            }
        }
        
        
        /**
         * 清除数据
         */
        public static function clear():void
        {
            _logBatch.clear();
        }
        
        
        
		public static function controlUIDisplay(display:Boolean):void
		{
			if(_ui == null)
                return;
            display ? _ui.show() : _ui.hide();
		}
        
        
        public function Debugger()
        {
        }
	}
}
