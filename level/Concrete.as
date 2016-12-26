package  level{
	
	import flash.display.MovieClip;
	import flash.ui.Keyboard;
	import flash.display.InteractiveObject;
	import flash.events.KeyboardEvent;
	
	
	public class Concrete extends MovieClip
	implements Solid, Tile{
		
		public function isPassable(): Boolean{
			return false;
		}
		public function Concrete() {
			stop();
		}
	}
	
}
