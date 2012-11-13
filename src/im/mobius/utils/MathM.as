package im.mobius.utils
{
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.geom.Vector3D;

    /**
     * 
     * 
     * @author mobius.chen
     * 
     */    
    public class MathM
    {
        public function MathM()
        {
        }
        
        
        /**
         * 检查两条线段是否相交.<p/>
         * 算法来源:http://hi.baidu.com/qi_hao/item/ed3e47de22d180fccb0c3999
         *  
         * @param p1
         * @param p2
         * @param q1
         * @param q2
         * @return 
         * 
         */        
        static public function checkLinesIntersecion(p1:Point, p2:Point, q1:Point, q2:Point):Boolean
        {
            //由两个点组成的矩形
            var rect1:Rectangle =
                new Rectangle(
                    Math.min(p1.x, p2.x), Math.min(p1.y, p2.y), 
                    Math.abs(p1.x - p2.x), Math.abs(p1.y - p2.y)
                );
            var rect2:Rectangle = 
                new Rectangle(
                    Math.min(q1.x, q2.x), Math.min(q1.y, q2.y), 
                    Math.abs(q1.x - q2.x), Math.abs(q1.y - q2.y)
                );
            
            if(!rect1.intersects(rect2))//快速排斥实验
                return false; 
            
            //跨立实验
            //(( P1 - Q1 ) × ( Q2 - Q1 )) * (( Q2 - Q1 ) × ( P2 - Q1 )) >= 0
            var v1:Vector3D = new Vector3D(p1.x - q1.x, p1.y - q1.y);
            var v2:Vector3D = new Vector3D(q2.x - q1.x, q2.y - q1.y);
            var v3:Vector3D = new Vector3D(p2.x - q1.x, p2.y - q2.y);
            var v4:Vector3D = v1.crossProduct(v2);
            var v5:Vector3D = v2.crossProduct(v3);
            if(v4.dotProduct(v5) >= 0)
                return true;
            
            return false;
        }
        
        
        /**
         * 检查某个点是否在指定线段上
         *  
         * @param q
         * @param p1
         * @param p2
         * @return 
         * 
         */        
        static public function pointOnLine(q:Point, p1:Point, p2:Point):Boolean
        {
            var v1:Vector3D = new Vector3D(p1.x - p2.x, p1.y - p2.y);
            v1.normalize();
            
            var v2:Vector3D = new Vector3D(q.x - p2.x, q.y - p2.y);
            v2.normalize();
            if(!v1.equals(v2))
                return false;
            
            v2.x = q.x - p1.x;
            v2.y = q.y - p1.y;
            v2.negate();
            if(!v1.equals(v2))
                return false;
            
            return true
        }
        
        
        /**
         * 检查线段是否经过一个矩形.
         *  
         * @param p1
         * @param p2
         * @param r
         * @return 
         * 
         */        
        public static function lineIntersectsRect(p1:Point, p2:Point, r:Rectangle):Boolean
        {
            var rTopRight:Point = new Point(r.x + r.width, r.y);
            var rBottomLeft:Point = new Point(r.x, r.y + r.height);
            
            //检测与两条对角线是否交叉
            return lineIntersectsLine(p1, p2, r.topLeft, r.bottomRight) ||
                   lineIntersectsLine(p1, p2, rTopRight, rBottomLeft) ||
                   (r.containsPoint(p1) && r.containsPoint(p2));
             
            //与四条边检测是否交叉
            /*
            return lineIntersectsLine(p1, p2, r.topLeft, rTopRight) ||
                   lineIntersectsLine(p1, p2, rTopRight, r.bottomRight) ||
                   lineIntersectsLine(p1, p2, r.bottomRight, rBottomLeft) ||
                   lineIntersectsLine(p1, p2, rBottomLeft, r.topLeft) ||
                   (r.containsPoint(p1) && r.containsPoint(p2));
            */
        }
        
        
        /**
         * 检查两条线段是否交叉.
         *  
         * @param p1
         * @param p2
         * @param q1
         * @param q2
         * @return 
         * 
         */        
        private static function lineIntersectsLine(p1:Point, p2:Point , q1:Point, q2:Point):Boolean
        {
            var q:Number = (p1.y - q1.y) * (q2.x - q1.x) - (p1.x - q1.x) * (q2.y - q1.y);
            var d:Number = (p2.x - p1.x) * (q2.y - q1.y) - (p2.y - p1.y) * (q2.x - q1.x);
            
            if( d == 0 )
                return false;
            
            var r:Number = q / d;            
            q = (p1.y - q1.y) * (p2.x - p1.x) - (p1.x - q1.x) * (p2.y - p1.y);
            var s:Number = q / d;
            
            if( r < 0 || r > 1 || s < 0 || s > 1 )
            {
                return false;
            }
            
            return true;
        }
    }
}