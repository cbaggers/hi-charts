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
    internal interface ILineGraphView
    {
        void UpdatePoints(Line line, ObservableList<GraphPoint> points);
        void SetHorizontalAxis(Axis a);
        void SetVerticalAxis(Axis a);
        void SetZoomType(string zoomType);
    }

    public class Line : Panel
    {
        LineGraph _graph { get { return Parent as LineGraph; } }

        string _color = "BLUE";
        public string Color {
            get
            {
                return _color;
            }
            set
            {
                _color = value ?? "BLUE";
            }
        }

        string _interpolate = "true";
        public string Interpolate {
            get
            {
                return _interpolate;
            }
            set
            {
                _interpolate = value ?? "BLUE";
            }
        }

        ObservableList<GraphPoint> _points;
        public ObservableList<GraphPoint> Points
        {
            get
            {
                if(_points==null) _points = new ObservableList<GraphPoint>(OnPointAdded, OnPointRemoved);
                return _points;
            }
        }

        internal void AddPoint(GraphPoint gp)
        {
            Points.Add(gp);
        }

        internal void RemovePoint(GraphPoint gp)
        {
            Points.Remove(gp);
        }

        void OnPointAdded(GraphPoint gp)
        {
            UpdatePointsNextFrame();
        }

        void OnPointRemoved(GraphPoint gp)
        {
            UpdatePointsNextFrame();
        }

        bool _willUpdatePointsNextFrame;
        internal void UpdatePointsNextFrame()
        {
            if(_willUpdatePointsNextFrame) return;
            UpdateManager.PerformNextFrame(DeferredPointUpdate, UpdateStage.Primary);
            _willUpdatePointsNextFrame = true;
        }

        void DeferredPointUpdate()
        {
            _willUpdatePointsNextFrame = false;
            _graph.ChartView.UpdatePoints(this, _points);
        }

        public void ClearPoints()
        {
            _points.Clear();
            _graph.ChartView.UpdatePoints(this, _points);
        }
    }

    public class LineGraph : Panel
    {
        internal ILineGraphView ChartView
        {
            get { return NativeView as ILineGraphView; }
        }

        protected override IView CreateNativeView()
        {
            if defined(Android)
            {
                return new AndroidLineGraph(this);
            }
            else if defined(iOS)
            {
                return base.CreateNativeView();
            }
            else
            {
                return base.CreateNativeView();
            }
        }

        //------------------

        double _hAxisStart = -1;
        double _hAxisEnd = -1;
        double _hAxisStep = -1;

        public double HAxisStart
        {
            get { return _hAxisStart; }
            set {
                _hAxisStart = value;
                if (_hAxisStart>=0 && _hAxisEnd>=0 && _hAxisStep>=0)
                    UpdateAxisNextFrame();
            }
        }


        public double HAxisEnd
        {
            get { return _hAxisEnd; }
            set {
                _hAxisEnd = value;
                if (_hAxisStart>=0 && _hAxisEnd>=0 && _hAxisStep>=0)
                    UpdateAxisNextFrame();
            }
        }

        public double HAxisStep
        {
            get { return _hAxisStep; }
            set {
                _hAxisStep = value;
                if (_hAxisStart>=0 && _hAxisEnd>=0 && _hAxisStep>=0)
                    UpdateAxisNextFrame();
            }
        }

        //------------------

        double _vAxisStart = -1;
        double _vAxisEnd = -1;
        double _vAxisStep = -1;

        public double VAxisStart
        {
            get { return _vAxisStart; }
            set {
                _vAxisStart = value;
                if (_vAxisStart>=0 && _vAxisEnd>=0 && _vAxisStep>=0)
                    UpdateAxisNextFrame();
            }
        }


        public double VAxisEnd
        {
            get { return _vAxisEnd; }
            set {
                _vAxisEnd = value;
                if (_vAxisStart>=0 && _vAxisEnd>=0 && _vAxisStep>=0)
                    UpdateAxisNextFrame();
            }
        }

        public double VAxisStep
        {
            get { return _vAxisStep; }
            set {
                _vAxisStep = value;
                if (_vAxisStart>=0 && _vAxisEnd>=0 && _vAxisStep>=0)
                    UpdateAxisNextFrame();
            }
        }

        bool _willUpdateAxisNextFrame;
        internal void UpdateAxisNextFrame()
        {
            if(_willUpdateAxisNextFrame) return;
            UpdateManager.PerformNextFrame(DeferredAxisUpdate, UpdateStage.Primary);
            _willUpdateAxisNextFrame = true;
        }

        void DeferredAxisUpdate()
        {
            _willUpdateAxisNextFrame = false;
            ChartView.SetHorizontalAxis(new Axis(_hAxisStart, _hAxisEnd, _hAxisStep));
            ChartView.SetVerticalAxis(new Axis(_vAxisStart, _vAxisEnd, _vAxisStep));
        }

        //------------------

        string _zoomType;
        public string ZoomType
        {
            get { return _zoomType; }
            set {
                _zoomType = value;
                UpdateZoomNextFrame();
            }
        }

        bool _willUpdateZoomNextFrame;
        internal void UpdateZoomNextFrame()
        {
            if(_willUpdateZoomNextFrame) return;
            UpdateManager.PerformNextFrame(DeferredZoomUpdate, UpdateStage.Primary);
            _willUpdateZoomNextFrame = true;
        }

        void DeferredZoomUpdate()
        {
            ChartView.SetZoomType(_zoomType);
        }
    }

    //----------------------------------------------------------------------

    extern(!Android) public class AndroidLineGraph {}

    [ForeignInclude(Language.Java, "java.util.ArrayList", "java.util.List", "android.graphics.Color",
                    "lecho.lib.hellocharts.gesture.ZoomType",
                    "lecho.lib.hellocharts.model.Axis",
                    "lecho.lib.hellocharts.model.Line",
                    "lecho.lib.hellocharts.model.LineChartData",
                    "lecho.lib.hellocharts.model.PointValue",
                    "lecho.lib.hellocharts.view.LineChartView")]
    [Require("Gradle.Dependency.Compile", "com.github.lecho:hellocharts-library:1.5.8@aar")]
    extern(Android) public class AndroidLineGraph : LeafView, ILineGraphView
    {
        LineGraph _host;

        public AndroidLineGraph(LineGraph host) : base(Create())
        {
            _host = host;
        }


        [Foreign(Language.Java)]
        static Java.Object Create()
        @{
            LineChartView chart = new LineChartView(com.fuse.Activity.getRootActivity());

            List<PointValue> values = new ArrayList<PointValue>();

            List<Line> lines = new ArrayList<Line>();

            LineChartData data = new LineChartData();

            data.setLines(lines);
            chart.setLineChartData(data);
            return chart;
        @}

        Dictionary<int, List<GraphPoint>> previousLines = new Dictionary<int, List<GraphPoint>>();
        Dictionary<int, int> lineIDs = new Dictionary<int, int>();

        public void UpdatePoints(Line line, ObservableList<GraphPoint> points)
        {
            int id = line.GetHashCode();

            List<GraphPoint> previousPoints;
            if (!previousLines.TryGetValue(id, out previousPoints))
            {
                previousPoints = new List<GraphPoint>();
                lineIDs[id] = lineIDs.Count;
            }
            previousLines[id] = previousPoints;
            int pLen = previousPoints.Count;
            int lineID = lineIDs[id];
            int i = 0;
            previousPoints.Clear();

            foreach(GraphPoint gp in points)
            {
                double x = i;
                double y = gp.Value;
                string l = gp.Label;
                if (i < pLen)
                {
                    UpdatePoint(lineID, i, x, y, l);
                } else {
                    AddPoint(lineID, x, y, l, line.Color, line.Interpolate.ToUpper()=="TRUE");
                }
                previousPoints.Add(gp);
                i+=1;
            }

            if (pLen > i)
                TrimPoints(lineID, i);

            StartAnimation();
        }

        [Foreign(Language.Java)]
        void AddPoint(int lineID, double x, double y, string label, string color, bool interp)
        @{
            LineChartView chart = (LineChartView)@{AndroidLineGraph:Of(_this).Handle:Get()};
            LineChartData data = (LineChartData)chart.getChartData();
            List<Line> lines = data.getLines();
            if (lines.size()<=lineID)
            {
                Line l = new Line(new ArrayList<PointValue>()).setColor(Color.parseColor(color)).setCubic(interp);
                l.setHasLabels(true);
                lines.add(l);
            }
            Line line = lines.get(lineID);

            PointValue p = new PointValue((float)x, 0);
            p.setTarget((float)x, (float)y);
            if (label!=null) p.setLabel(label);
            line.getValues().add(p);
        @}

        [Foreign(Language.Java)]
        void UpdatePoint(int lineID, int i, double x, double y, string label)
        @{
            LineChartView chart = (LineChartView)@{AndroidLineGraph:Of(_this).Handle:Get()};
            LineChartData data = (LineChartData)chart.getChartData();
            Line line = data.getLines().get(lineID);
            PointValue p = line.getValues().get(i);
            p.setTarget((float)x, (float)y);
            if (label!=null) p.setLabel(label);
        @}

        [Foreign(Language.Java)]
        void TrimPoints(int lineID, int trimPoint)
        @{
            LineChartView chart = (LineChartView)@{AndroidLineGraph:Of(_this).Handle:Get()};
            LineChartData data = (LineChartData)chart.getChartData();
            Line line = data.getLines().get(lineID);
            line.setValues(line.getValues().subList(0, trimPoint));
        @}

        [Foreign(Language.Java)]
        void StartAnimation()
        @{
            LineChartView chart = (LineChartView)@{AndroidLineGraph:Of(_this).Handle:Get()};
            chart.startDataAnimation();
        @}

        internal void Clear()
        {
            previousLines = new Dictionary<int, List<GraphPoint>>();
            ClearInner();
        }

        [Foreign(Language.Java)]
        void ClearInner()
        @{
            LineChartView chart = (LineChartView)@{AndroidLineGraph:Of(_this).Handle:Get()};

            List<Line> lines = new ArrayList<Line>();

            LineChartData data = (LineChartData)chart.getChartData();
            LineChartData newData = new LineChartData();
            if (data.getAxisXBottom()!=null)
                newData.setAxisXBottom(data.getAxisXBottom());
            if (data.getAxisYLeft()!=null)
                newData.setAxisYLeft(data.getAxisYLeft());

            newData.setLines(lines);
            chart.setLineChartData(newData);
        @}

        public void SetHorizontalAxis(Axis a)
        {
            SetHorizontalAxisInner((float)a.Start, (float)a.End, (float)a.Step);
        }

        [Foreign(Language.Java)]
        void SetHorizontalAxisInner(float start, float end, float step)
        @{
            LineChartView chart = (LineChartView)@{AndroidLineGraph:Of(_this).Handle:Get()};
            LineChartData data = (LineChartData)chart.getChartData();
            data.setAxisXBottom(Axis.generateAxisFromRange(start, end, step));
        @}

        public void SetVerticalAxis(Axis a)
        {
            SetVerticalAxisInner((float)a.Start, (float)a.End, (float)a.Step);
        }

        [Foreign(Language.Java)]
        void SetVerticalAxisInner(float start, float end, float step)
        @{
            LineChartView chart = (LineChartView)@{AndroidLineGraph:Of(_this).Handle:Get()};
            LineChartData data = (LineChartData)chart.getChartData();
            data.setAxisYLeft(Axis.generateAxisFromRange(start, end, step));
        @}

        [Foreign(Language.Java)]
        public void SetZoomType(string _zoomType)
        @{
            LineChartView chart = (LineChartView)@{AndroidLineGraph:Of(_this).Handle:Get()};
            String zoomType = _zoomType.toUpperCase();

            if (zoomType.equals("HORIZONTAL"))
                chart.setZoomType(ZoomType.HORIZONTAL);
            else if (zoomType.equals("VERTICAL"))
                chart.setZoomType(ZoomType.VERTICAL);
            else if (zoomType.equals("HORIZONTAL_AND_VERTICAL"))
                chart.setZoomType(ZoomType.HORIZONTAL_AND_VERTICAL);
        @}

    }

    //----------------------------------------------------------------------

}
