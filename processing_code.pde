import processing.serial.*;
import java.util.ArrayList;

Serial port;

// ================= SETTINGS =================
float radarRadius;
float maxDist = 90;
int totalRings = 9;

// ================= RADAR ANGLES =================
float frontVertical = 90;
float rearVertical  = 90;
float frontHorizontal = 45;
float rearHorizontal  = 45;

// ================= LASER ANGLES (FROM ARDUINO) =================
float laserFrontPan = 90;
float laserFrontTilt = 90;
float laserRearPan = 90;
float laserRearTilt = 90;

// ================= LASER STATE =================
boolean frontLaserActive = false;
boolean rearLaserActive  = false;

// ================= ENEMY CLASS =================
class Enemy {
  float vert, dist;
  float x, y;
  int lastSeen;
  boolean front;

  Enemy(float v, float d, boolean isFront) {
    vert = v;
    dist = d;
    front = isFront;
    lastSeen = millis();
    updatePos();
  }

  void update(float v, float d) {
    vert = v;
    dist = d;
    lastSeen = millis();
    updatePos();
  }

  void updatePos() {
    float r = map(min(dist, maxDist), 0, maxDist, 0, radarRadius);
    float ang = radians(map(vert, 0, 180, -180, 0));
    x = r * cos(ang);
    y = front ? r * sin(ang) : -r * sin(ang);
  }

  void draw() {
    noStroke();
    if (dist <= 20) fill(255, 0, 0, 230);
    else if (dist < 50) fill(255, 200, 0, 220);
    else fill(front ? color(0, 255, 120, 200)
                    : color(0, 200, 255, 200));
    ellipse(x, y, 9, 9);
  }
}

ArrayList<Enemy> enemies = new ArrayList<>();

// ================= SETUP =================
void setup() {
  fullScreen(P2D);
  smooth(8);
  radarRadius = min(width, height) * 0.35;

  port = new Serial(this, Serial.list()[0], 9600);
  port.bufferUntil('\n');
}

// ================= DRAW =================
void draw() {
  background(6, 10, 14);

  translate(width/2, height/2);
  drawGrid();
  drawSweeps();
  drawEnemies();
  cleanupEnemies();

  resetMatrix();
  drawHeader();
  drawHUDLeft();
  drawHUDRight();   // <-- laser info here
  drawFooter();
}

// ================= GRID =================
void drawGrid() {
  noStroke();
  for (int i = totalRings; i >= 1; i--) {
    float r = radarRadius * i / float(totalRings);
    if (i <= 2) fill(255, 0, 0, 40);
    else if (i <= 5) fill(255, 255, 0, 30);
    else fill(0, 150, 90, 20);
    ellipse(0, 0, r * 2, r * 2);
  }

  stroke(0, 200, 150, 120);
  noFill();
  ellipse(0, 0, radarRadius * 2, radarRadius * 2);
  for (int i = 1; i <= totalRings; i++) {
    float r = radarRadius * i / float(totalRings);
    ellipse(0, 0, r * 2, r * 2);
  }
  line(-radarRadius, 0, radarRadius, 0);
  line(0, -radarRadius, 0, radarRadius);
}

// ================= SWEEPS =================
void drawSweeps() {
  strokeWeight(2);

  stroke(0, 255, 160, 180);
  float af = radians(180 - frontVertical);
  line(0, 0, radarRadius * cos(af), -radarRadius * sin(af));

  stroke(0, 200, 255, 180);
  float ar = radians(rearVertical);
  line(0, 0, radarRadius * cos(ar), radarRadius * sin(ar));

  strokeWeight(1);
}

// ================= HUD RIGHT =================
void drawHUDRight() {
  int xLabel = width - 420;
  int xColon = width - 200;
  int xValue = width - 180;
  int y = 160;

  textAlign(LEFT);
  textSize(18);
  fill(180);

  text("Front Radar Vertical", xLabel, y); y+=20;
  text("Front Radar Horizontal", xLabel, y); y+=20;
  text("Front Laser Pan", xLabel, y); y+=20;
  text("Front Laser Tilt", xLabel, y); y+=20;
  text("Front Laser Status", xLabel, y); y+=30;

  text("Rear Radar Vertical", xLabel, y); y+=20;
  text("Rear Radar Horizontal", xLabel, y); y+=20;
  text("Rear Laser Pan", xLabel, y); y+=20;
  text("Rear Laser Tilt", xLabel, y); y+=20;
  text("Rear Laser Status", xLabel, y);

  y = 160;
  for (int i = 0; i < 10; i++) {
    text(":", xColon, y);
    y += (i == 4 ? 30 : 20);
  }

  y = 160;
  fill(200);
  text(int(frontVertical)+"°", xValue, y); y+=20;
  text(int(frontHorizontal)+"°", xValue, y); y+=20;
  text(int(laserFrontPan)+"°", xValue, y); y+=20;
  text(int(laserFrontTilt)+"°", xValue, y); y+=20;

  fill(frontLaserActive ? color(255,0,0) : color(0,255,120));
  text(frontLaserActive ? "ON" : "OFF", xValue, y); y+=30;

  fill(200);
  text(int(rearVertical)+"°", xValue, y); y+=20;
  text(int(rearHorizontal)+"°", xValue, y); y+=20;
  text(int(laserRearPan)+"°", xValue, y); y+=20;
  text(int(laserRearTilt)+"°", xValue, y); y+=20;

  fill(rearLaserActive ? color(255,0,0) : color(0,255,120));
  text(rearLaserActive ? "ON" : "OFF", xValue, y);
}

// ================= SERIAL =================
void serialEvent(Serial s) {
  String line = trim(s.readStringUntil('\n'));
  if (line == null) return;

  if (line.startsWith("F:")) handleRadar(line.substring(2), true);
  else if (line.startsWith("R:")) handleRadar(line.substring(2), false);
  else if (line.startsWith("LF:")) handleLaser(line.substring(3), true);
  else if (line.startsWith("LR:")) handleLaser(line.substring(3), false);
}

// ================= RADAR DATA =================
void handleRadar(String data, boolean front) {
  String[] v = split(data, ',');
  if (v.length < 3) return;

  float vert = front ? float(v[0]) : float(v[0]) - 180;
  float tilt = float(v[1]);
  float dist = float(v[2]);
  if (dist < 0) return;

  if (front) {
    frontVertical = vert;
    frontHorizontal = tilt;
    frontLaserActive = dist <= 50;
  } else {
    rearVertical = vert;
    rearHorizontal = tilt;
    rearLaserActive = dist <= 50;
  }

  for (Enemy e : enemies) {
    if (e.front == front &&
        abs(e.vert - vert) < 4 &&
        abs(e.dist - dist) < 8) {
      e.update(vert, dist);
      return;
    }
  }
  enemies.add(new Enemy(vert, dist, front));
}

// ================= LASER DATA =================
void handleLaser(String data, boolean front) {
  String[] v = split(data, ',');
  if (v.length < 2) return;

  if (front) {
    laserFrontPan = float(v[0]);
    laserFrontTilt = float(v[1]);
  } else {
    laserRearPan = float(v[0]);
    laserRearTilt = float(v[1]);
  }
}

// ================= HELPERS =================
void drawEnemies() {
  for (Enemy e : enemies) e.draw();
}

void cleanupEnemies() {
  for (int i = enemies.size()-1; i >= 0; i--) {
    if (millis() - enemies.get(i).lastSeen > 1200)
      enemies.remove(i);
  }
}

// ================= UI =================
void drawHeader() {
  textAlign(CENTER);
  fill(0, 255, 200);
  textSize(40);
  text("AIR DEFENCE SYSTEM", width/2, 50);
}

void drawHUDLeft() {
  float c = getClosest();
  int x = 30, y = 160;

  textAlign(LEFT);
  textSize(18);
  fill(180);

  text("System Status", x, y); y+=24;
  text("Closest Target", x, y); y+=20;
  text("Active Targets", x, y); y+=20;

  y = 160;
  text(":", 190, y); y+=24;
  text(":", 190, y); y+=20;
  text(":", 190, y);

  y = 160;
  fill(c <= 20 ? color(255,0,0) :
       c < 50 ? color(255,200,0) :
                color(0,255,120));
  text(c <= 20 ? "DANGER" : c < 50 ? "SERIOUS" : "SAFE", 210, y);
  fill(200);
  y+=24;
  text(c < 999 ? int(c)+" cm" : "N/A", 210, y);
  y+=20;
  text(enemies.size(), 210, y);
}

void drawFooter() {
  fill(180);
  textAlign(CENTER);
  textSize(18);
  text("Developed by - The Bit Blazzer", width/2, height-40);
  text("Department of CSE, Primeasia University", width/2, height-20);
}

float getClosest() {
  float c = 999;
  for (Enemy e : enemies)
    if (e.dist < c) c = e.dist;
  return c;
}
