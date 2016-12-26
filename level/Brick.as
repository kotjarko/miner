package  level{
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.display.FrameLabel;
	import flash.display.Scene;
	import flash.geom.Point;
	
	public class Brick extends MovieClip
	implements Solid, Tile{
		
		static public const APPEARING = "Appearing";
		static public const DISAPPEARING = "Disappearing";
		static public const DISAPPEARED = "Disappeared";
		
		public function isPassable(): Boolean{
			return isDisappeared();
		}
		public function Brick() {
			// constructor code
			addEventListener(Event.ENTER_FRAME, OnEnterFrame);
			stop();
		}
		
		public function isDisappeared(): Boolean{
			return currentLabel == DISAPPEARED;
		}
		public function isAppearing(){
			return currentLabel == APPEARING;
		}
		
		public function OnEnterFrame(e: Event){
			
			if ( currentFrameLabel == DISAPPEARED)
				dispatchEvent(new Event(DISAPPEARED));
			
			if( currentLabel == APPEARING )
				dispatchEvent(new Event(APPEARING));
			
			if(MustBeAppeared()){
				gotoAndPlay(APPEARING);
				dispatchEvent(new Event(DISAPPEARED));
			}
			if(currentFrame == 1)
				stop();
		}
		
		public function MustBeAppeared():Boolean{
			if (currentLabel == DISAPPEARING)
			{				
				return isAnybodyUp();
			}
			return false;
		}
		public function Disappear(): Boolean {
			//stage.getObjectsUnderPoint(new Point(this.x, this.y - this.height)).length == 0
			if (currentFrame == 1 && !isAnybodyUp() ) {
				gotoAndPlay(2);
				return true;
			}else{
				return false;
			}	
		}
		
		private function isAnybodyUp(): Boolean {
			var objects: Array = LodeRunner.getObjectsUnder(this.x, this.y - this.height, 
										   this.height);
			if(objects.length == 0)
				return false;
			
			var object: MovieClip;
			for (var i: String in objects) {
				object = LodeRunner.getMovieClipForCollide(objects[i]);
				if (object is Solid)
					if ( !Solid (object).isPassable())
						return true;
			}			
			
			return false;
		}
	}
	
}
