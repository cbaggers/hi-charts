using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse;
using Fuse.Triggers;
using Fuse.Controls;
using Fuse.Controls.Native;
using Fuse.Controls.Native.Android;

namespace HelloCharts
{
    public struct Axis
	{
        public double Start;
        public double End;
        public double Step;

        public Axis(double start, double end, double step)
        {
            Start = start;
            End = end;
            Step = step;
        }
    }

    public class GraphPoint : Node
	{
		double _value;
		public double Value {
			get
            {
                return _value;
            }
			set
            {
				_value = value;
				MarkDirty();
			}
		}

		string _label = "";
		public string Label {
			get
            {
                return _label;
            }
			set
            {
				_label = value ?? "";
				MarkDirty();
			}
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			Line chart = Parent as Line;
			if(chart != null) chart.AddPoint(this);
		}

		protected override void OnUnrooted()
		{
			base.OnUnrooted();
			Line chart = Parent as Line;
			if(chart != null) chart.RemovePoint(this);
		}

		void MarkDirty()
		{
			Line chart = Parent as Line;
			if(chart != null) chart.UpdatePointsNextFrame();
		}
	}

    public sealed class LineGraphPoint : GraphPoint
	{
	}
}
