package im.mobius.debug
{
    public interface IDebugerUI
    {
        /**
         * 控制是否出现 
         * @param display
         * 
         */        
        function controlDisplay(display:Boolean):void;
        
        function updateData():void;
    }
}