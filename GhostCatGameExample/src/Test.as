package
{
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ghostcat.algorithm.traversal.PathOptimizer;

	public class Test extends Sprite
	{
		public function Test()
		{
			graphics.lineStyle(0,0x000000);
			for (var i:int = 0;i < 5;i++)
			{
				graphics.moveTo(0,i * 10);
				graphics.lineTo(50,i * 10);
				graphics.moveTo(i * 10,0);
				graphics.lineTo(i * 10,50);
			}
			
			var path:Array = [new Point(0,0),new Point(1,0),new Point(2,0),new Point(2,1),new Point(2,2),new Point(2,3),new Point(3,3),new Point(4,3),new Point(5,3)];
			path = PathOptimizer.findPath(path);
			
			graphics.lineStyle(0,0xFF0000);
			graphics.moveTo(0,0);
			while (path.length)
			{
				var p:Point = path.shift();
				graphics.lineTo(p.x * 10,p.y * 10);
				trace(p);
			}
		}
	}
}