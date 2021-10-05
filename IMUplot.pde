/**
* M5Stack IMU Graph 
* @author　Nob.Shinjo
* @version　1.0.0
*/
import processing.serial.*;
import processing.opengl.*;
import processing.core.*;
import processing.awt.PSurfaceAWT;
import java.util.*;
import java.awt.event.KeyEvent;
import controlP5.*;


// static final int axis_color[][] = {{200,50,50} ,{60,120,200} ,{200,200,80} };//x_axis(1)is RED,y_axis(2)is BLUE,z_axis(3)is YELLOW
// static final int x_color = 0,y_color = 1,z_color = 2; //1is red 2is blue 3is yellow
// static final int text_size = 30;
// static final int box_width = 100;
// static final int box_height = 50;
// static final int box_depth = 160;

// static final int box_Xpotision = 1600;
// static final int box_Ypotision = 850;
// static final int box_textpotision =-  180;
// static final int circle_R = 270;
// static final int Diamond = 100;
// static final int Rectangle_width = 160;
// static final int Rectangle_height = 35;

// char data;//data

// float gx, gy, gz;
// float ax, ay, az;
// float mx, my, mz;


// float roll = 0,pitch = 0,yaw = 0;
// int a = 1;//回転方向


// circleMonitor roll_circle;
// circleMonitor pitch_circle;
// circleMonitor yaw_circle;//未実装


// Window 初期サイズ
static final int INIT_WINDOW_WIDTH = 900;
static final int INIT_WINDOW_HEIGHT = 600;

// Window 現在のサイズ
int currentWindowWidth = INIT_WINDOW_WIDTH;
int currentWindowHeight = INIT_WINDOW_HEIGHT;

// Window 表示状態
enum WindowState {
    FullScreen,
    Normal;
}
// Window 現在の表示状態
WindowState currentWindowState = WindowState.Normal; 

// static final char GYRO = 1;
// static final char ACCEL = 2;
// static final char MAG = 3;
// static final char XYZ_rotations = 4;

// Chart 
RealTimeChart xAccelGraph;
RealTimeChart yAccelGraph;
RealTimeChart zAccelGraph;
RealTimeChart xGyroGraph;
RealTimeChart yGyroGraph;
RealTimeChart zGyroGraph;
RealTimeChart pitchGraph;
RealTimeChart rollGraph;
RealTimeChart yawGraph;

// 自己姿勢Chart
BoxChart boxChart;

// Chart Common Settings
ChartSettings realTimeChartSettings;

// ControlP5 GUI
// http://www.sojamo.de/libraries/controlP5/reference/index.html
ControlP5 cp5;
// COM設定
Button comConnect;
DropdownList comPort;
DropdownList comRate;

// Serial Communication
Serial serialPort;
String portName = "";
int baudRate= 0;

// Recieve Data
float dataTime;
float xAccel;
float yAccel;
float zAccel;

float xGyro;
float yGyro;
float zGyro;

float pitch;
float roll;
float yaw;

void settings() {    
    //画面描画モード 3D
    size(INIT_WINDOW_WIDTH,INIT_WINDOW_HEIGHT,P3D);
    /**
    * TODO
    * 3D Graphics driver ERROR
    */
    // size(INIT_WINDOW_WIDTH,INIT_WINDOW_HEIGHT);
}

/**
* 設定
*/
void setup() {
    // Windowリサイズ有効
    surface.setResizable(true); 
    // Windowタイトル 
    surface.setTitle("M5Stack IMU Graph");
    
    // Default 60fps
    surface.setFrameRate(30);
    // Draws all geometry with smooth (anti-aliased) edges
    smooth();

    // GUI
    setupGUI();
    
    // Real Time Chart
    setupRealTimeChart();
    setupBoxChart();

    
    // roll_circle = new circleMonitor("roll",350,800,x_color);
    // pitch_circle = new circleMonitor("pitch",700,800,y_color);
    
}

/**
* controlP5 GUI 初期設定
 */
void setupGUI(){
    int positionX = 20;
    int positionY = 20;
    int marginX = 200;
    int marginY = 20;

    cp5 = new ControlP5(this);

    // COM接続
    final int[] comRates = {
        300, 1200, 2400, 4800, 9600, 14400, 19200, 28800, 38400, 57600, 115200
    };

// COMポートリスト取得    
    List comPorts = Arrays.asList(Serial.list());

    // GUI Font設定
    ControlFont guiFont = new ControlFont(createFont("Meiryo UI", 12, true)); 
    cp5.setFont(guiFont);
    
    // COM接続設定 
    comConnect = cp5.addButton("com_connect")
            .setLabel("Disconnected")
            .setPosition(positionX, positionY)
            .setSize(100,40);
            // .setSwitch(true);
            // setSwitch命令使うと 警告: java.lang.IllegalArgumentException: wrong number of arguments

    // COMポート
    comPort = cp5.addDropdownList("com_port")
            .setPosition(positionX + marginX, positionY)
            .setSize(150,40*5)
            .setBarHeight(40)
            .setItemHeight(40)
            .setOpen(false);
    if (comPorts.size() <=0 ) {        
        // COM接続可能ポートがない場合
        comPort.setLabel("COM Port not found");    
    }else{
        // COM接続可能ポートがある場合
        comPort.setLabel("Select COM Port");        
    }
    comPort.setItems(comPorts);

    // COM速度
    comRate = cp5.addDropdownList("com_rate")
            .setLabel("Select COM Rate")
            .setPosition(positionX + marginX * 2, positionY)
            .setSize(150,40*5)
            .setBarHeight(40)
            .setItemHeight(40)
            .setOpen(false);
    for (int i = 0; i < comRates.length; ++i) {
        comRate.addItem(String.valueOf(comRates[i]) + " bps", i);     
    }

    // 大文字のみ→大文字・小文字有効
    comConnect.getCaptionLabel().toUpperCase(false);
    comPort.getCaptionLabel().toUpperCase(false);
    comPort.getValueLabel().toUpperCase(false);
    comRate.getCaptionLabel().toUpperCase(false);
    comRate.getValueLabel().toUpperCase(false);    
}

/**
* Real Time Chart 初期設定
 */
void setupRealTimeChart(){
    // Chart Settings
    // realTimeChartSettings = new ChartSettings(400,150,60,50);
    realTimeChartSettings = new ChartSettings();
    realTimeChartSettings
        .setWidth(300)
        .setHeight(150)
        .setMarginX(60)
        .setMarginY(50);
    int initRealTimeChartX = 80;
    int initRealTimeChartY = 100;

    // 加速度
    xAccelGraph = new RealTimeChart(
        "Accel X",
        initRealTimeChartX,
        initRealTimeChartY,
        realTimeChartSettings.getWidth(),
        realTimeChartSettings.getHeight(),
        "Time [sec.]",
        "Accelation [G]",
        color(255,0,0)
        );
    yAccelGraph = new RealTimeChart(
        "Accel Y",
        initRealTimeChartX,
        initRealTimeChartY + (realTimeChartSettings.getHeight() + realTimeChartSettings.getMarginY()),
        realTimeChartSettings.getWidth(),
        realTimeChartSettings.getHeight(),
        "Time [sec.]",
        "Accelation [G]",        
        color(0,255,0)
        );
    zAccelGraph = new RealTimeChart(
        "Accel Z",
        initRealTimeChartX,
        initRealTimeChartY + 2*(realTimeChartSettings.getHeight() + realTimeChartSettings.getMarginY()),
        realTimeChartSettings.getWidth(),
        realTimeChartSettings.getHeight(),
        "Time [sec.]",
        "Accelation [G]",        
        color(0,0,255)
        );

    // ジャイロ
    xGyroGraph = new RealTimeChart(
        "Gyro X",
        initRealTimeChartX + (realTimeChartSettings.getWidth() + realTimeChartSettings.getMarginX()),
        initRealTimeChartY,
        realTimeChartSettings.getWidth(),
        realTimeChartSettings.getHeight(),
        "Time [sec.]",
        "Angular Verocity [dps]",
        color(255,0,0)
        );
    yGyroGraph = new RealTimeChart(
        "Gyro Y",
        initRealTimeChartX + (realTimeChartSettings.getWidth() + realTimeChartSettings.getMarginX()),
        initRealTimeChartY + (realTimeChartSettings.getHeight() + realTimeChartSettings.getMarginY()),
        realTimeChartSettings.getWidth(),
        realTimeChartSettings.getHeight(),
        "Time [sec.]",
        "Angular Verocity [dps]",
        color(0,255,0)
        );
    zGyroGraph = new RealTimeChart(
        "Gyro Z",
        initRealTimeChartX + (realTimeChartSettings.getWidth() + realTimeChartSettings.getMarginX()),
        initRealTimeChartY + 2*(realTimeChartSettings.getHeight() + realTimeChartSettings.getMarginY()),
        realTimeChartSettings.getWidth(),
        realTimeChartSettings.getHeight(),
        "Time [sec.]",
        "Angular Verocity [dps]",
        color(0,0,255)
        );

    // 自己姿勢
    pitchGraph = new RealTimeChart(
        "Pitch",
        initRealTimeChartX + 2*(realTimeChartSettings.getWidth() + realTimeChartSettings.getMarginX()),
        initRealTimeChartY,
        realTimeChartSettings.getWidth(),
        realTimeChartSettings.getHeight(),
        "Time [sec.]",
        "Angle [deg.]",
        color(255,0,0)
        );
    rollGraph = new RealTimeChart(
        "Roll",
        initRealTimeChartX + 2*(realTimeChartSettings.getWidth() + realTimeChartSettings.getMarginX()),
        initRealTimeChartY + (realTimeChartSettings.getHeight() + realTimeChartSettings.getMarginY()),
        realTimeChartSettings.getWidth(),
        realTimeChartSettings.getHeight(),
        "Time [sec.]",
        "Angle [deg.]",
        color(0,255,0)
        );
    yawGraph = new RealTimeChart(
        "Yaw",
        initRealTimeChartX + 2*(realTimeChartSettings.getWidth() + realTimeChartSettings.getMarginX()),
        initRealTimeChartY + 2*(realTimeChartSettings.getHeight() + realTimeChartSettings.getMarginY()),
        realTimeChartSettings.getWidth(),
        realTimeChartSettings.getHeight(),
        "Time [sec.]",
        "Angle [deg.]",
        color(0,0,255)
        );
}

 void setupBoxChart(){
    boxChart = new BoxChart();
    boxChart
        .setTitle("M5Stack")
        .setX(1250)
        .setY(350)
        .setExtent(200)
        .setWidth(54)
        .setHeight(17)
        .setDepth(54);
}
/**
* 描画
*/
void draw(){
    background(25);
   
    // 加速度
    xAccelGraph.draw();
    yAccelGraph.draw();
    zAccelGraph.draw();
    
    // ジャイロ
    xGyroGraph.draw();
    yGyroGraph.draw();
    zGyroGraph.draw();
   
    // 自己位置姿勢
    pitchGraph.draw();
    rollGraph.draw();
    yawGraph.draw();

    boxChart.draw();
}

void clearChartAll(){
    
    xAccelGraph.clear();
    yAccelGraph.clear();
    zAccelGraph.clear();

    xGyroGraph.clear();
    yGyroGraph.clear();
    zGyroGraph.clear();

    pitchGraph.clear();
    rollGraph.clear();
    yawGraph.clear();

    boxChart.clear();
}

void appendChartAll(){
        xAccelGraph.append(dataTime,xAccel);
        yAccelGraph.append(dataTime,yAccel);
        zAccelGraph.append(dataTime,zAccel);

        xGyroGraph.append(dataTime,xGyro);
        yGyroGraph.append(dataTime,yGyro);
        zGyroGraph.append(dataTime,zGyro);

        pitchGraph.append(dataTime,pitch);
        rollGraph.append(dataTime,roll);
        yawGraph.append(dataTime,yaw);

        boxChart.setPosture(pitch,roll,yaw);
}
/**
* KEY入力イベント
*/
void keyPressed() {
    switch(keyCode) {        
        case KeyEvent.VK_F11:
            // F11 全画面切り替え
            if (currentWindowState ==  WindowState.FullScreen) {
                // 通常Windowへ変更
                currentWindowState = WindowState.Normal;
                setNormalWindow();
            } else if (currentWindowState ==  WindowState.Normal) {
                // FullScreenへ変更
                currentWindowState = WindowState.FullScreen;
                setFullScreen();
            }
            break;
        default :            
        break;	
    }
}
/**
" 通常Window化する
*/
void setNormalWindow() {
    // 記憶していたWindowサイズに戻す
    surface.setSize(currentWindowWidth,currentWindowHeight);
    surface.setLocation(
        displayWidth / 2 - currentWindowWidth / 2,
        displayHeight / 2 - currentWindowHeight / 2
       );    
    surface.setResizable(true); 
    surface.setAlwaysOnTop(false);
}


/**
" 全画面表示にする
* */
void setFullScreen() {    
    // 現在Windowサイズを記憶
    currentWindowWidth = width;
    currentWindowHeight = height;
    surface.setLocation(0, 0);
    surface.setSize(displayWidth, displayHeight);
    surface.setResizable(false); 
    surface.setAlwaysOnTop(true);
}

/**
* COMポートを接続する
 */
void com_connect(){
      if (comConnect.isOn()){
        if(portName == "") {
            serialPortClose();
            return;
        }
        if(baudRate <= 0){            
            serialPortClose();
            return;
        }       
       
        try{            
            serialPort = new Serial(this, portName, baudRate);
            serialPortOpen();
            clearChartAll();

        } catch (RuntimeException ex) {
            // Swallow error if port can't be opened, keep port closed.
           serialPortClose();
        }
    }else{
        if (serialPort != null) {
            serialPort.stop();
        }
        serialPortClose();
    }
}

/**
* Serialポート Close処理
*/
void serialPortOpen(){
    comConnect.setLabel("Connected");
    comConnect.setOn();
    //DEBUG
    System.out.printf("portName= %s, baudRate= %d\n", portName , baudRate);
    System.out.printf("Connected COM Port.\n");
}

/**
* Serialポート Close処理
*/
void serialPortClose(){
    comConnect.setLabel("Disconnected");
    comConnect.setOff();
    serialPort = null;
    
    // DEBUG
    System.out.printf("Disconnected COM Port.\n");
}
/**
* COMポートを選択する
 */
void com_port(int n){
    portName = comPort.getItem(n).get("text").toString();
    // DEBUG
    System.out.printf("portName= %s\n",portName);
}
/**
* COM通信速度を選択する
 */
void com_rate(int n){    
    // String s = comRate.getStringValue();
    String s = comRate.getItem(n).get("text").toString();
    baudRate = Integer.parseInt(s.substring(0, s.length()-4));
    // DEBUG
    System.out.printf("baudRate= %d\n",baudRate);
}


void serialEvent(Serial p){
    String recieveStrings = p.readStringUntil('\n');
    if (recieveStrings != null) {
        recieveStrings = trim(recieveStrings);//trimで空白消去
       // float sensors[] = float(split(recieveStrings, ','));// ,cut output
       String recieveData[] = split(recieveStrings, ',');
       if(isNumber(recieveData[0])){
            dataTime= float(recieveData[0]); 
            xAccel = float(recieveData[1]);
            yAccel = float(recieveData[2]);
            zAccel = float(recieveData[3]); 

            xGyro = float(recieveData[4]);
            yGyro = float(recieveData[5]);
            zGyro = float(recieveData[6]);  

            pitch = float(recieveData[7]);  
            roll = float(recieveData[8]);  
            yaw = float(recieveData[9]);  

            appendChartAll();

            println(recieveData); //processingのシリアルモニタに数値を表示 
        }
    }
}

/**
 * 文字列が数値であるか判定する
 */
public boolean isNumber(String num) {
    String regex = "[+-]?\\d*(\\.\\d+)?";
    return num.matches(regex);
}






// void ypr_box(float r,float p,float y) {//YPR
//     ambientLight(200,200,200);
//     pointLight(200,200,200,box_Xpotision,box_Ypotision,70);//light potison
//     lightFalloff(1,0,0);
//     lightSpecular(0,0,0);

//     pushMatrix();
//     translate(box_Xpotision,box_Ypotision);
//     textSize(text_size);// title
//     fill(80,200,200);     
//     textAlign(LEFT, BOTTOM);
//     text("YPR", box_textpotision, box_textpotision);

//     rotateY(radians(y));//Y_rotations is changed  raw(Z_rotation)
//     rotateZ(radians(a * r));
//     rotateX(radians( -a *-  p));
//     fill(70, 180, 230);
//     stroke(200,255,230);
//     box(box_width,box_height,box_depth);

//     stroke(60,120,200);
//     line(0, 0, 0, 200, 0, 0);//X rotation(pitch) blue 
//     stroke(200,200,80);
//     line(0, 0, 0, 0, -200, 0);//Y rotation(yaw)yellow
//     stroke(200,50,50);
//     line(0, 0, 0, 0, 0, 200);//Z rotation(roll) red
//     popMatrix();
// }

// void ryp_box(float r ,float p ,float y) {//RYP
//     ambientLight(100,100,100);
//     pointLight(100,100,100,box_Xpotision,box_Ypotision,70);//light potison
//     lightFalloff(1,0,0);
//     lightSpecular(0,0,0);

//     pushMatrix();
//     translate(box_Xpotision + 400,box_Ypotision);
//     textSize(text_size);// title
//     fill(80,200,200);
//     textAlign(LEFT, BOTTOM);
//     text("RYP", box_textpotision, box_textpotision);

//     rotateX(radians(a * p));
//     rotateY(radians(y));//Y_rotations is changed  raw(Z_rotation)
//     rotateZ(radians( -a *-  r));
//     fill(200, 60, 50);
//     stroke(200,130,80);
//     box(box_width,box_height,box_depth);

//     stroke(60,120,200);
//     line(0, 0, 0, 200, 0, 0);//X rotation(pitch) blue 
//     stroke(200,200,80);
//     line(0, 0, 0, 0, -200, 0);//Y rotation(yaw)yellow
//     stroke(200,50,50);
//     line(0, 0, 0, 0, 0, 200);//Z rotation(roll) red
//     popMatrix();
// }

// class circleMonitor{
//     String TITLE;
//     int X_POSITION,Y_POSITION;
//     int X_LENGTH,Y_LENGTH;
//     int c;
//     circleMonitor(String _TITLE, int _X_POSITION, int _Y_POSITION,int _COLOR) {
//         TITLE = _TITLE;
//         X_POSITION = _X_POSITION;
//         Y_POSITION = _Y_POSITION;
//         c = _COLOR;
//     }

//     void graphDraw(float ang) {
//         pushMatrix();
//         translate(X_POSITION,Y_POSITION);
//         textSize(text_size);// title
//         fill(80,200,200);
//         textAlign(LEFT, BOTTOM);
//         text(TITLE, -circle_R / 2, -circle_R / 2);

//         strokeWeight(1);
//         stroke(255,255,255);
//         fill(25);
//         ellipse(0,0,circle_R,circle_R);

//         fill(axis_color[c][0],axis_color[c][1],axis_color[c][2]);
//         textSize(18);
//         text(ang, -circle_R / 2 - 60,0);

//         line( -circle_R / 2,0,circle_R / 2,0);
//         line(0, -circle_R / 2,0,circle_R / 2);

//         strokeWeight(1);
//         stroke(220);
//         fill(axis_color[c][0],axis_color[c][1],axis_color[c][2]);
//         translate(0,0);  
//         rotate(radians(ang)); 
//         rect( -Rectangle_width / 2, -Rectangle_height / 2,Rectangle_width,Rectangle_height);
//         popMatrix();
//     }
// } /*

// void roll_circle(float r){//roll circle
// pushMatrix();
// translate(circle_Xpotision,circle_Ypotision);
// textSize(text_size);// title
// fill(80,200,200);
// textAlign(LEFT, BOTTOM);
// text("roll", -circle_R/2, -circle_R/2);

// strokeWeight(1);
// stroke(255,255,255);
// fill(25);
// ellipse(0,0,circle_R,circle_R);
// line(-circle_R/2,0,circle_R/2,0);
// line(0,-circle_R/2,0,circle_R/2);

// fill(200,50,50);
// textSize(18);
// text(r,-circle_R/2-60,0);

// strokeWeight(2);
// stroke(20,50,50);
// fill(200,50,50);
// translate(0,0);  
// rotate(radians(r)); 
// rect(0,0,Rectangle_width,Rectangle_height);
// popMatrix();
// }
// void pitch_circle(float p){// pitch circle
// pushMatrix();
// translate(circle_Xpotision+350,circle_Ypotision);
// textSize(text_size);// title
// fill(80,200,200);
// textAlign(LEFT, BOTTOM);
// text("pitch", -circle_R/2, -circle_R/2);

// strokeWeight(1);
// stroke(255,255,255);
// fill(25);
// ellipse(0,0,circle_R,circle_R);

// fill(60,120,200);
// textSize(18);
// text(p,-circle_R/2-60,0);

// line(-circle_R/2,0,circle_R/2,0);
// line(0,-circle_R/2,0,circle_R/2);
// strokeWeight(1);
// stroke(220);
// fill(60,120,200);
// stroke(60,120,200);
// translate(0,0);  
// rotate(radians(-p)); 
// rect(0,0,Rectangle_width,Rectangle_height);
// popMatrix();
// }*/
// void yaw_circle(float ang) {// yaw circle
//     pushMatrix();
//     translate(700 + 350,800);//picthの円の描写位置から(+700,+0)
//     textSize(text_size);// title
//     fill(80,200,200);
//     textAlign(LEFT, BOTTOM);
//     text("yaw", -circle_R / 2, -circle_R / 2);

//     strokeWeight(1);
//     stroke(230,230,230);
//     fill(25);
//     ellipse(0,0,circle_R,circle_R);

//     fill(200,200,80);
//     textSize(18);
//     text(ang, -circle_R / 2 - 60,0);

//     strokeWeight(1);
//     stroke(220);
//     line( -circle_R / 2,0,circle_R / 2,0);
//     line(0, -circle_R / 2,0,circle_R / 2);
//     fill(200,200,80);
//     stroke(200,200,90);
//     translate(0,0);  
//     rotate(radians( -ang)); 
//     beginShape();
//     for (int i = 0; i < 4; i++) {
//         int R;
//         if (i % 2 == 0) {
//             R = Diamond / 3;
//         } else {
//             R = Diamond;
//         }
//         vertex(R * cos(radians(90 * i)), R * sin(radians(90 * i)));
//     } endShape(CLOSE);
//     popMatrix();
// }

/**
* Real Time Chart
*/
class RealTimeChart{
    // Chart Title
    private String title;
    // Chart 位置
    private int x;
    private int y;
    // Chartサイズ
    private int width;
    private int height;
    // 軸ラベル
    private String xAxisLabel;
    private String yAxisLabel;

    // Chart Data
    private FloatList dataX;
    private FloatList dataY; 
    // Chart Dataサイズ
    static final int MAX_DATA_SIZE = 500;
    
    // Chart 描画色
    private color regionFillColor = color(50);
    private color regionLineColor = color(100);
    private color titleTextColor = color(0,255,255);
    private color axisLineColor = color(160);
    private color axisTextColor = color(255);
    private color dataLineColor;
    
    // Text Size
    private int chartTitleTextSize = 15;
    private int axisLabelTextSize = 12;
    private int axisValueTextSize = 12;

    // Stroke Weight
    private int regionStrokeWeight = 1;
    private int axisStrokeWeight = 1;
    private int dataStrokeWeight = 1;
    
    /**
    * RealTimeChart コンストラクタ
    */
    public RealTimeChart(
        String title, 
        int x, int y,int width, int height,
          String xAxisLabel,String yAxisLabel,
          color c
          ) {
        
        this.title = title;
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
        this.xAxisLabel = xAxisLabel;
        this.yAxisLabel = yAxisLabel;
        this.dataLineColor = c;
                
        dataX = new FloatList();
        dataY = new FloatList();       
        
    }

    public RealTimeChart(String title, int x, int y, int width, int height, String xAxisLabel, String yAxisLabel){
        this(title, x, y, width, height, xAxisLabel, yAxisLabel, color(0, 255, 0));
    }
    public RealTimeChart(String title, int x, int y, int width, int height){
        this(title, x, y, width, height, "X", "Y", color(0, 255, 0));
    }


    /**
    * Chart領域、タイトル描画
    */
    private void drawChartRegion(){
        // Chart領域描画
        fill(regionFillColor);
        stroke(regionLineColor);
        strokeWeight(regionStrokeWeight);
        rect(0, 0, width, height);
        
        // Chartタイトル
        textSize(chartTitleTextSize);
        fill(titleTextColor);
        textAlign(LEFT, BOTTOM);
        text(title, 0, 0);
    }

    /**
    * X軸描画
    */
    private void drawXAxis(){
        // X軸
        stroke(axisLineColor);
        strokeWeight(axisStrokeWeight);
        line(0, height/2, width, height/2);
        
        // X軸 目盛線        
        pushMatrix();
        // Chart Y軸中央 原点へ移動
        translate(0, height/2);
        float rangeWidth = GetRangeWidth(dataX);
        float axisStep = GetAxisStep(rangeWidth);
        float dataMin = 0.0;
        if(dataX.size()!=0){
            dataMin = dataX.min();
        }
        // System.out.printf("X Axis : range= %.2f, axisStep= %.2f, min= %.2f\n", rangeWidth, axisStep, dataMin);
        
        for (int i = 0; i < Math.floor(rangeWidth/axisStep); i++) {
            float step = (i + (float)Math.ceil(dataMin/axisStep)) * axisStep;
            float position = (step - dataMin) / rangeWidth * width;
            int digits = getPrecision(step);

            // 正値
            stroke(axisLineColor);
            strokeWeight(axisStrokeWeight);
            line(position, -5, position, +5); 

            textSize(axisValueTextSize); 
            fill(axisTextColor);        
            if (i != 0){
                textAlign(CENTER, TOP);
            }else{
                textAlign(LEFT, TOP);
            }
            // 最小値 0.0以外の初回ループのときはSkip
            // if(i == 0 && dataMin != 0){
            //     continue;
            // }
            text(nf(step, 0, digits), position, +2);    
        }
        popMatrix();

        // X軸ラベル
        pushMatrix();
        textSize(axisLabelTextSize);
        fill(axisTextColor);
        textAlign(CENTER, TOP);
        text(xAxisLabel, width/2, height);     
        popMatrix();   
    }

    /**
    * Y軸描画
    */
    private void drawYAxis(){
        // Y軸
        // Region枠と同一

        // Y軸 目盛線        
        pushMatrix();
        // Chart Y軸中央 原点へ移動
        translate(0,height/2);
        float maxRange = GetMaxAbsRange(dataY);
        float axisStep = GetAxisStep(maxRange);
        for (int i = 0; i <= Math.ceil(maxRange/axisStep); i++) {
            float step = i * axisStep;
            float position = step/maxRange * height/2;
            int digits = getPrecision(step);

            // 負値
            if(i != 0){
                line(0, position, 5, position);

                textSize(axisValueTextSize); 
                fill(axisTextColor);       
                textAlign(RIGHT, CENTER);
                text(nf(-step, 0, digits), -2, position);  
            }
            // 正値
            line(0, -position, 5, -position);
            
            textSize(axisValueTextSize); 
            fill(axisTextColor);       
            textAlign(RIGHT, CENTER);
            text(nf(+step, 0, digits), -2, -position);    
        }
        popMatrix();

        // Y軸ラベル
        pushMatrix();        
        textSize(axisLabelTextSize);
        fill(axisTextColor);
        textAlign(CENTER, BOTTOM);
        translate(0, height/2);
        rotate(radians(-90));
        text(yAxisLabel, 0, -30);
        popMatrix();
    }

    /**
    * データLine描画
     */
    private void drawData(){
        pushMatrix();

        // 原点移動
        translate(0, height/2);

        // スケーリング
        //float scaleX = GetRangeWidth(dataX) / width;
        //float scaleY = 2 * GetMaxAbsRange(dataY) / height;
        // scale(scaleX, scaleY);

        float scaleX = width / GetRangeWidth(dataX);
        float scaleY = height / (2 * GetMaxAbsRange(dataY));
        
        // Line描画設定
        stroke(dataLineColor);
        strokeWeight(dataStrokeWeight); 
        noFill();
        
        int dataSize = dataX.size() < dataY.size()  ? dataX.size() : dataY.size();

        // 連続線描画
        beginShape();
        for (int i = 0; i < dataSize; i++) {
            vertex((dataX.get(i) - dataX.min()) * scaleX, dataY.get(i) * scaleY);
        }
        endShape();

        popMatrix();

        //System.out.printf("dataX Size=  %d ,min= %.2f ,max= %.2f\n", dataX.size(), dataX.min(), dataX.max());

    }

    /**
    * データ内 最大絶対値取得
    */
    private float GetMaxAbsRange(FloatList dataList){
        float maxRange = 0.0;
        if (dataList.size()==0){
            maxRange = 1.0;
        }else{
            maxRange = abs(dataList.max()) > abs(dataList.min()) ? abs(dataList.max()) : abs(dataList.min());
        }
        return maxRange;
    }

    /**
     * データ内 Range幅 取得
    */
    private float GetRangeWidth(FloatList dataList){
        float range = 0.0;
        if (dataList.size()==0){
            range = 1.0;
        }else{
            range = dataList.max() - dataList.min();
        }
        return range;
    }

    /**
    * 軸目盛間隔を取得する
    * @param  value  数値範囲
    * https://imagingsolution.net/program/autocalcgraphstep/
    */
    private float GetAxisStep(float value){
        // 指数
        double exponent = Math.pow(10, Math.floor( Math.log(value) / Math.log(10) ));
        // 仮数
        double significand = value / exponent;
        // グラフ間隔
        double axisStep;

        if (significand < 1.5) {
            axisStep = 0.2 * exponent;
        } else if (significand < 3.5) {
            axisStep = 0.5 * exponent;
        } else if (significand <= 5.0)        {
            axisStep = 1.0 * exponent;
        } else {
            axisStep = 2.0 * exponent;
        }
        return (float)axisStep;
    }

    /**
    * 小数点以下桁数
     */
    public int getPrecision(float value){
        // 文字列変換
        String tmpString = String.valueOf(value);

        // 文末が ".0"とか".00000"で終わってるやつは全部桁０とする
        // if(match(tmpString, "^.*\\.0+$")){
        //     return 0;
        // }
        int index = tmpString.indexOf(".");
        return tmpString.substring(index + 1).length();
    }

    /**
    * Chartを描画更新する
    */
    public void draw(){
        // 描画座標 保存
        pushMatrix();
        
        // Chart 描画位置へ移動
        translate(x, y);
        
        // Chart 領域枠
        drawChartRegion();        
        // X軸タイトル, X軸描画        
        drawXAxis();        
        // Y軸タイトル, Y軸描画
        drawYAxis();

        // Chart Line描画
        drawData();
        
        // 描画座標 再展開
        popMatrix();
    }
    
    /**
    * Chartデータを追加して描画更新する
    */
    public void draw(float valueX, float valueY) {       
        append(valueX, valueY);
        draw();            
    }
    
    /**
    * Chartにデータを追加する
    */
    public void append(float valueX, float valueY) {
        //データ格納
        if (dataX.size() >= MAX_DATA_SIZE) {
            dataX.remove(0);
        }        
        dataX.append(valueX);
        
        if (dataY.size() >= MAX_DATA_SIZE) {
            dataY.remove(0);
        }
        dataY.append(valueY);
    }

    /**
     * Chart内のデータをクリアする
     */
    public void clear(){
        dataX.clear();
        dataY.clear();
    }   
}

/**
* Chart Settings
*/
class ChartSettings{
    private int width;
    private int height;
    private int marginX;
    private int marginY;
    
    public ChartSettings(int width, int height, int marginX, int marginY){
        this.width = width;
        this.height = height;
        this.marginX = marginX;
        this.marginY = marginY;
    }
    public ChartSettings(int width, int height){
        this(width, height, 0, 0);
    }
    public ChartSettings(){

    }

    public int getWidth() {
        return width;
    }
    public ChartSettings setWidth(int width) {
        this.width = width;
        return this;
    }
    
    public int getHeight() {
        return height;
    }
    public ChartSettings setHeight(int height){
        this.height = height;
        return this;
    }

    public int getMarginX() {
        return marginX;
    }
    public ChartSettings setMarginX(int marginX){
        this.marginX = marginX;
        return this;
    }

    public int  getMarginY() {
        return marginY;
    }
    public ChartSettings setMarginY(int marginY){
        this.marginY = marginY;
        return this;
    }
}

/**
 */
class BoxChart{
    // Chart Title
    private String title;
    // Chart 位置
    private int x = 0;
    private int y = 0;
    private int extent = 20;
    // Box サイズ
    private int width = 10;
    private int height = 10;
    private int depth = 10;
    // Box 姿勢
    private float pitch = 0.0;
    private float roll = 0.0;
    private float yaw =0.0;
    // 座標軸
    private int axisLength = 100;
    // 座標軸幅
    private int dataStrokeWeight = 1;
    // Text Size
    private int chartTitleTextSize = 15;
     // Chart 描画色
    private color regionFillColor = color(50);
    private color regionLineColor = color(100);
    private color titleTextColor = color(0,255,255);
    private color boxFillColor = color(60,200,200);
    private color boxLineColor = color(10,100,100);
    private color pitchLineColor = color(255,0,0);
    private color rollLineColor = color(0,0,255);
    private color yawLineColor = color(0,255,0);

    /**
     * コンストラクタ
     */
    public BoxChart(String title, int x, int y, int extent, int width, int height, int depth){
        this.title = title;
        this.x = x;
        this.y = y;
        this.extent = extent;
        this.width = width;
        this.height = height;
        this.depth = depth;
        this.axisLength = (int)(extent*0.3);
    }
    public BoxChart(){

    }

    public String getTitle(){
        return this.title;
    }
    public BoxChart setTitle(String title){
        this.title = title;
        return this;
    }
    public int getX(){
        return this.x;
    }
    public BoxChart setX(int x){
        this.x = x;
        return this;
    }
    public int getY(){
        return this.y;
    }
    public BoxChart setY(int y){
        this.y = y;
        return this;
    }
    public int getExtent(){
        return this.extent;
    }
    public BoxChart setExtent(int extent){
        this.extent = extent;
        this.axisLength = (int)(extent*0.3);
        return this;
    }
    public int getWidth(){
        return this.width;
    }
    public BoxChart setWidth(int width){
        this.width = width;
        return this;
    }
    public int getHeight(){
        return this.height;
    }
    public BoxChart setHeight(int height){
        this.height = height;
        return this;
    }
    public int getDepth(){
        return this.depth;
    }
    public BoxChart setDepth(int depth){
        this.depth = depth;
        return this;
    }
    public int getAxisLength(){
        return this.axisLength;
    }
    public BoxChart setAxisLength(int axisLength){
        this.axisLength = axisLength;
        return this;
    }

    // 姿勢を設定する
    void setPosture(float pitch, float roll, float yaw){
        this.pitch = pitch;
        this.roll = -roll;
        this.yaw = 180 -  yaw;
    }

    // 姿勢を初期化する
    void clear(){
        this.pitch = 0.0;
        this.roll = 0.0;
        this.yaw = 0.0;
    }
    
    // BOXを描画する
    void drawBox(float pitch, float roll, float yaw){
        setPosture(pitch,roll,yaw);
        draw();
    }
    // Boxを描画する
    void draw() {
        drawTitle();

        pushMatrix();
        
        translate(x,y);

        // 背景描画
        stroke(regionLineColor);
        // fill(regionFillColor);
        noFill();
        circle(0,0,extent);

        // スケーリング
        scale(1.5);

        float c1 = cos(radians(roll));
        float s1 = sin(radians(roll));
        float c2 = cos(radians(pitch));
        float s2 = sin(radians(pitch));
        float c3 = cos(radians(yaw));
        float s3 = sin(radians(yaw));
        // 行列乗算・・・あってる？
        // http://www.info.hiroshima-cu.ac.jp/~miyazaki/knowledge/tech0007.html
        applyMatrix(c2*c3,   s1*s3+c1*c3*s2, c3*s1*s2-c1*s3, 0,
                    -s2,     c1*c2,          c2*s1,          0,
                    c2*s3,   c1*s2*s3-c3*s1, c1*c3+s1*s2*s3, 0,
                    0,       0,              0,              1);

        // BOX描画        
        stroke(boxLineColor);
        fill(boxFillColor);
        box(width, height, depth);
        
        //X rotation(pitch)
        stroke(pitchLineColor); 
        strokeWeight(dataStrokeWeight); 
        line(0, 0, 0, axisLength, 0, 0); 
        //Y rotation(roll)
        stroke(rollLineColor);
        strokeWeight(dataStrokeWeight); 
        line(0, 0, 0, 0, axisLength, 0);
        //Z rotation(yaw)
        stroke(yawLineColor);
        strokeWeight(dataStrokeWeight); 
        line(0, 0, 0, 0, 0, axisLength);

        popMatrix();
    }

    /**
     * Chartタイトルを描画する
     */
    void drawTitle(){
        pushMatrix();

        translate(x,y);
        // Chartタイトル
        textSize(chartTitleTextSize);
        fill(titleTextColor);
        textAlign(LEFT, BOTTOM);
        text(title, -extent/2, -extent/2);

        popMatrix();
    }
}
