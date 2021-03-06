package
{
	import flash.display.Sprite;
	
	import ghostcat.debug.EnabledSWFScreen;
	import ghostcat.display.residual.ResidualScreen;
	import ghostcat.display.transfer.Paper3D;
	import ghostcat.manager.RootManager;
	import ghostcat.operation.RepeatOper;
	import ghostcat.operation.TweenOper;
	import ghostcat.util.Util;
	import ghostcat.util.easing.Back;
	
	/**
	 * 3D旋转例子
	 * 
	 * 顺带加了特效
	 * 
	 * @author flashyiyi
	 * 
	 */
	public class Paper3DExample extends Sprite
	{
		public var p:Paper3D;
		public function Paper3DExample()
		{
			new EnabledSWFScreen(stage);
			
			p = new Paper3D(new TestRepeater());
			p.x = 50;
			p.y = 50;
			addChild(p);
			
			addChild(Util.createObject(new ResidualScreen(200,200),{fadeSpeed:0.95,blurSpeed:6,children:[p]}));
			
			new RepeatOper([new TweenOper(p,5000,{rotationAtY:180,ease:Back.easeInOut}),new TweenOper(p,5000,{rotationAtY:0,ease:Back.easeInOut})]).execute();
		}
	}
}