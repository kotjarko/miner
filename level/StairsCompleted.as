package level {
	
	import flash.display.MovieClip;
	import flash.events.Event;
	
	
	public class StairsCompleted extends Stairs
		implements Completed{
		
		
		public function StairsCompleted() {
			// constructor code
			addEventListener(Event.ADDED_TO_STAGE, OnAddedToStage);
			addEventListener(Event.ENTER_FRAME, OnEnterFrame);			
		}
		
		public function OnAddedToStage(e: Event){
			gotoAndStop(1);
			visible = false;
		}
		public function OnEnterFrame(e: Event){
			if (totalFrames == currentFrame) {
				stop();
			}
		}
	}
	
}
