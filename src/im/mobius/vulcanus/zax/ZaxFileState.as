package im.mobius.vulcanus.zax
{
    public class ZaxFileState
    {
        /*** 打开，可读不可写状态状态 */
        //static public const READ:String = "read";
        /**
         *  打开，可写不可读状态
         */        
        //static public const APPEND:String = "write";
        
        
        static public const OPEN:String = "open";
        /*** 关闭状态 */
        static public const CLOSED:String = "closed";
        /*** 操作状态，无法相应其他操作 */
        static public const OPERATING:String = "operating";
        /*** 无效状态 */
        static public const INVALID:String = "invalid";
        
        public function ZaxFileState()
        {
        }
    }
}