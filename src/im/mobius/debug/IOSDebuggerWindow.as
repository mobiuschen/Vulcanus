package im.mobius.debug
{
	import flash.display.Sprite;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import im.mobius.view.RawComponent;

	public class IOSDebuggerWindow extends Sprite implements IConsoleWindow
	{
        static public const SWITCH_TAB_EVENT:String = "switchTabEvent"; 
        
        private var _textField:TextField;
        
        private var _textWidth:Number = 500;//for iphone4
        
        private var _tabContainer:Sprite;
        
		private var _initialized:Boolean = false;
        
		private var _logType:String = "";
        
		private var _callOut:Sprite;
        
        private var screenScale:Number;
        
        
		public function IOSDebuggerWindow()
		{
			super();
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}

		protected function onAddedToStage(e:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);

			if (_initialized == false)
			{
				initSkin();
				_initialized = true;
			}
		}

		protected function initSkin():void
		{
            /*var rect:Rectangle = ScreenAdaptiveUtil.ACTUAL_SCREEN_RECT;
            var scale:Number = 
                ScreenAdaptiveUtil.getRectScale(
                    ScreenAdaptiveUtil.IPHONE4_RECT, ScreenAdaptiveUtil.ACTUAL_SCREEN_RECT
                ).vScale;*/
            var scale:Number = 1.0;
			var h:Number = stage.fullScreenHeight;
            _textWidth *= scale;
            
			this.graphics.clear();
			this.graphics.beginFill(0, 0.5);
			this.graphics.drawRoundRect(0, 0, _textWidth, h, 10, 10);
			this.graphics.endFill();
            
            createTabs();
            
            var txtStyle:StyleSheet = new StyleSheet();
            txtStyle.setStyle("p", {fontFamily: "Lucida Sans Unicode", fontSize: 13, color: "#00FF00"});
            txtStyle.setStyle(".t", {leading: -20});
            txtStyle.setStyle(".m", {marginLeft: 90});
            var tf:TextField;
            tf = new TextField();
            tf.y = _tabContainer.height + 10;
            tf.height = h - tf.y;
            tf.width = _textWidth;
            tf.multiline = true;
            tf.wordWrap = true;
            tf.styleSheet = txtStyle;
            _textField = tf;
            addChild(_textField);
            
			_callOut = new Sprite();
			_callOut.graphics.clear();
			_callOut.graphics.beginFill(0, 0.5);
			_callOut.graphics.drawRect(0, 0, 60 * scale, 100 * scale);
			_callOut.graphics.endFill();
			_callOut.x = -_callOut.width;
            _callOut.y = (h - _callOut.height) >> 1;
			addChild(_callOut);
			_callOut.addEventListener(MouseEvent.CLICK, toggle);
            
            x = stage.fullScreenWidth;
		}
        
        
        
        private function createTabs():void
        {
            _tabContainer = new Sprite();
            var btn:Sprite;
            var w:Number, h:Number;
            const columnNum:int = 3;
            for(var i:int = 0, n:int = LogType.ALL_TYPES.length; i < n; i++)
            {
                btn = RawComponent.createBtn(LogType.ALL_TYPES[i]);
                w = btn.width + 5;
                h = btn.height + 5;
                btn.x = (i % columnNum) * w + 10;
                btn.y = int(i / columnNum) * h + 10;
                btn.name = LogType.ALL_TYPES[i];
                btn.addEventListener(MouseEvent.CLICK, onClickTab);
                _tabContainer.addChild(btn);
            }
            addChild(_tabContainer);
        }
        
        

		private function toggle(e:Event):void
		{
			if (this.x == stage.fullScreenWidth)
				this.x -= _textWidth;
			else
				this.x += _textWidth;
		}

		public function set dataProvider(value:Vector.<LogEntity>):void
		{
			if (!value)
			{
				return;
			}

			_textField.htmlText = value.join("");
			_textField.scrollV = _textField.maxScrollV;
		}

		public function isHidden():Boolean
		{
            return this.x == stage.fullScreenWidth;
		}

		public function hide():void
		{
			if (this.parent)
			{
				this.stage.focus = this.stage
				this.parent.removeChild(this);
			}
		}
		
		public function show():void
		{
            if (this.x == stage.fullScreenWidth)
				this.x -= _textWidth;
		}
        
        
        public function onClickTab(evt:MouseEvent):void
        {
            var tabName:String = evt.currentTarget.name;
            dispatchEvent(new DataEvent(SWITCH_TAB_EVENT, false, false, tabName));
        }
        
	}
}
