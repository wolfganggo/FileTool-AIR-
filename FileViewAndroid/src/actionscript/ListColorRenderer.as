// ActionScript file

package actionscript
{
	// containers\mobile\myComponents\MySimpleColorRenderer .as
	import flash.filesystem.File;
	
	import spark.components.LabelItemRenderer;
	
	import actionscript.Utilities;
	
	public class ListColorRenderer extends LabelItemRenderer
	{
		public function ListColorRenderer() {
			super();
		}
		
		override protected function drawBackground(unscaledWidth:Number, unscaledHeight:Number):void {
			// Define a var to hold the color.
			var myColor:uint;
			if (this.data == null) {
				return;
			}
			if (this.data.data == null) {
				return;
			}
			
			var entry:String = data.data as String;
			if (entry == "d" && this.selected) {
				myColor = 0xCCCCBB;
			}
			else if (entry == "d" && !this.selected) {
				myColor = 0xEEDDBB;
			}
			else if (this.selected) {
				myColor = 0xCCCCCC;
			}
			else {
				myColor = 0xEEEEEE;
			}
			
			// Determine the RGB color value from the label property.
			//if (data == "red")
			//	myColor = 0xFF0000;
			//if (data == "green")
			//	myColor = 0x00FF00;
			//if (data == "blue")
			//	myColor = 0x0000FF;
			
			graphics.beginFill(myColor, 1);
			graphics.drawRect(0, 0, unscaledWidth, unscaledHeight); 
			
		}
	}
}

//=======================================================
/*
\history

WGo-2015-02-27: created

*/

