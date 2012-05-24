package
{
	import com.junkbyte.console.ConsoleTestSuite;
	import com.junkbyte.eval.EvalTestSuite;

	import org.flexunit.internals.TraceListener;
	import org.flexunit.runner.FlexUnitCore;

	import flash.display.Sprite;

	public class TestRunner extends Sprite
	{
		public function TestRunner()
		{
			var core : FlexUnitCore = new FlexUnitCore();

			core.addListener(new TraceListener());

			core.run(ConsoleTestSuite, EvalTestSuite);
		}
	}
}
