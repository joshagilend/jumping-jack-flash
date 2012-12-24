package guns.attribs
{
	import flash.events.Event;

	public class AttribEvent extends Event
	{		
		
		// Possible attribute events
		public static const ATTRIB_CHANGE_REL:String = "attribChangeRelative";		// relative, value = 3, then new val is old + 3
		public static const ATTRIB_CHANGE_ABS:String = "attribChangeAbsolute";		// absolute, value = 3, then new val is 3

		private var _attrib:String;
		private var _value:Number		// this is absolute

		public function AttribEvent(type:String, attrib:String, val:Number, bubbles:Boolean=true, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			_attrib = attrib;
			_value = val;
		}
		
		public function get attrib():String {
			return _attrib;
		}
		public function get value():Number {
			return _value;
		}
		
		
	}
}