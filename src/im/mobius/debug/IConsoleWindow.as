package im.mobius.debug
{
	import flash.events.IEventDispatcher;

	public interface IConsoleWindow extends IEventDispatcher
	{
		function set dataProvider(value:Vector.<LogEntity>):void;
        
		function isHidden():Boolean;
		
		function hide():void;
        function show():void;
	}
}