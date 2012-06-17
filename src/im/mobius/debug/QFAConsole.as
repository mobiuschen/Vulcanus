package im.mobius.debug
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.DataEvent;

	/**
	 * 调试信息控制台
	 * @author youyeelu
	 *
	 */
	public class QFAConsole
	{
		static public var consoleWindowClass:Class;
		
        static public var consoleWindow:IConsoleWindow;

		static private var _logBatch:LogBatch;
        
        static private var _crtType:String = LogType.MISC;
        
        static private var _stage:DisplayObjectContainer;
        

		/**
		 * 构造函数
		 * @param stage 舞台
		 * @param windowClass 调试信息窗口
		 *
		 */
		public function QFAConsole(stage:DisplayObjectContainer, windowClass:Class = null)
		{
			super();
			consoleWindowClass = windowClass;
            
            _logBatch = new LogBatch();
            //init all types
            for(var i:int = 0, n:int = LogType.ALL_TYPES.length; i < n; i++)
            {
                _logBatch.createLog(LogType.ALL_TYPES[i], "Init " + LogType.ALL_TYPES[i]);
            }
            
			_stage = stage;
		}


		/**
		 * 清除Log
		 *
		 */
		static public function clear():void
		{
			_logBatch.clear();

            printToScreen();
		}

		/**
		 * 记录信息
		 * @param msg 需要记录的信息
		 * @param type 信息类型默认为Log
		 *
		 */
		static public function log(msg:String, type:String, print:Boolean = true):void
		{
			if(_logBatch == null)
                _logBatch = new LogBatch();

            var l:LogEntity = _logBatch.createLog(type, msg);
            trace(l.toStringWithoutFormat());

            if(print)
                printToScreen();
		}

        
		/**
		 * 显示信息输出面板
		 *
		 */
		static public function showWindow():void
		{
			if (!consoleWindow)
			{
				consoleWindow = new consoleWindowClass() as IConsoleWindow;
                if(consoleWindow is IOSDebuggerWindow)
                {
                    consoleWindow.addEventListener(IOSDebuggerWindow.SWITCH_TAB_EVENT, onSwitchTab);
                }
			}

			if (consoleWindow.isHidden)
			{
				_stage.addChildAt(consoleWindow as DisplayObject, _stage.numChildren);
			}
            consoleWindow.dataProvider = 
                _logBatch.getLogsByType(_crtType == null || _crtType == "" ? LogType.MISC : _crtType);
		}

		/**
		 * 隐藏信息输出面板
		 *
		 */
		static public function hideWindow():void
		{
			if (consoleWindow)
			{
				if (!consoleWindow.isHidden)
				{
					consoleWindow.hide();
				}
			}
		}
        
        
        static private function onSwitchTab(evt:DataEvent):void
        {
            var type:String = evt.data;
            //Debugger.log("switch to " + type, LogType.USER_ACTION);
            if(LogType.ALL_TYPES.indexOf(type) < 0)
                return;
            
            consoleWindow.dataProvider = _logBatch.getLogsByType(type);
        }
        
        
        static public function printToScreen():void
        {
            if (consoleWindow && DisplayObject(consoleWindow).stage)
            {
                consoleWindow.dataProvider = 
                    _logBatch.getLogsByType(_crtType == null || _crtType == "" ? LogType.MISC : _crtType);
            }
        }
        
	}
}
