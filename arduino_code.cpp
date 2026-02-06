#include <Servo.h>
#include <U8g2lib.h>
#include <Wire.h>

// ================= OLED =================
U8G2_SH1106_128X64_NONAME_F_HW_I2C u8g2(
  U8G2_R0, U8X8_PIN_NONE
);

// ================= SERVOS =================
Servo panServo;
Servo frontServo;
Servo rearServo;

// ===== LASERS =====
Servo laserPanFront;
Servo laserTiltFront;
Servo laserPanRear;
Servo laserTiltRear;

const float laserRearSideOffset = 2.0; // cm (left side)

// ================= PINS =================
const int panPin   = 2;
const int frontPin = 3;
const int rearPin  = 4;

// Front laser
const int laserPanFrontPin  = 5;
const int laserTiltFrontPin = 6;
const int laserFrontPin     = 8;

// Rear laser
const int laserPanRearPin   = 10;
const int laserTiltRearPin  = 11;
const int laserRearPin      = 12;

const int buzzerPin = 9;

const int frontTrig = A0;
const int frontEcho = A1;
const int rearTrig  = A2;
const int rearEcho  = A3;

// ================= ANGLES =================
const int panMin  = 0;
const int panMax  = 180;
const int tiltMin = 30;
const int tiltMax = 80;

// ===== LASER GEOMETRY =====
const float laserOffsetDeg     = degrees(atan2(6.0, 3.5));
const float laserForwardOffset = 3.5;

// ================= SPEED =================
const unsigned long panInterval   = 60;
const unsigned long tiltInterval  = 8;
const unsigned long ultraInterval = 120;
const unsigned long oledInterval  = 300;

// ===== SIREN =====
int sirenFreq = 600;
int sirenDir  = 1;
unsigned long lastSirenStep = 0;

// ================= STATE =================
int panAngle = 0;
int panDir   = 1;

int tiltAngle = tiltMin;
int tiltDir   = 1;

unsigned long lastPanTime   = 0;
unsigned long lastTiltTime  = 0;
unsigned long lastUltraTime = 0;
unsigned long lastOledTime  = 0;

// ===== LASER ANGLE FEEDBACK =====
int laserFrontPanAngle  = 90;
int laserFrontTiltAngle = 90;
int laserRearPanAngle   = 90;
int laserRearTiltAngle  = 90;

// ================= ULTRASONIC =================
long readDistance(int t, int e) {
  digitalWrite(t, LOW); delayMicroseconds(2);
  digitalWrite(t, HIGH); delayMicroseconds(10);
  digitalWrite(t, LOW);
  long d = pulseIn(e, HIGH, 8000);
  if (!d) return -1;
  return d * 0.034 / 2;
}

// ================= LASER AIM =================
void aimLaserFront(int radarPan, int radarTilt, long dist) {
  float theta = radians(radarPan - 90);
  float panCorr = degrees(atan(laserForwardOffset / dist)) * sin(theta);

  laserFrontPanAngle =
    constrain(radarPan - panCorr, 0, 180);
  laserPanFront.write(laserFrontPanAngle);

  laserFrontTiltAngle =
    constrain(radarTilt + laserOffsetDeg, 0, 180);
  laserTiltFront.write(laserFrontTiltAngle);
}

void aimLaserRear(int radarPan, int radarTilt, long dist) {
  float theta = radians(radarPan - 90);

  // ----- SIDE OFFSET CORRECTION (LEFT) -----
  float sideCorrDeg =
    degrees(atan(laserRearSideOffset / dist)) * cos(theta);

  // ----- FORWARD OFFSET CORRECTION -----
  float forwardCorrDeg =
    degrees(atan(laserForwardOffset / dist)) * sin(theta);

  laserRearPanAngle =
    constrain(radarPan - forwardCorrDeg + sideCorrDeg, 0, 180);
  laserPanRear.write(laserRearPanAngle);

  laserRearTiltAngle =
    constrain(radarTilt + laserOffsetDeg, 0, 180);
  laserTiltRear.write(laserRearTiltAngle);
}


// ================= OLED =================
void updateOLED(long dist, bool front) {
  u8g2.clearBuffer();

  if (dist < 0 || dist > 50) {
    u8g2.setFont(u8g2_font_logisoso28_tf);
    u8g2.drawStr(28, 55, "SAFE");
  } else {
    u8g2.setFont(u8g2_font_6x12_tf);
    u8g2.drawStr(14, 16, front ? "FRONT TARGET" : "REAR TARGET");

    u8g2.setFont(dist <= 20 ?
      u8g2_font_logisoso28_tf :
      u8g2_font_logisoso24_tf);
    u8g2.drawStr(10, 55, dist <= 20 ? "DANGER" : "SERIOUS");
  }

  u8g2.sendBuffer();
}

// ================= SIREN =================
void siren() {
  unsigned long now = millis();
  if (now - lastSirenStep > 12) {
    lastSirenStep = now;
    sirenFreq += sirenDir * 40;
    if (sirenFreq > 2200 || sirenFreq < 600) sirenDir *= -1;
    tone(buzzerPin, sirenFreq);
  }
}

// ================= SETUP =================
void setup() {
  panServo.attach(panPin);
  frontServo.attach(frontPin);
  rearServo.attach(rearPin);

  laserPanFront.attach(laserPanFrontPin);
  laserTiltFront.attach(laserTiltFrontPin);
  laserPanRear.attach(laserPanRearPin);
  laserTiltRear.attach(laserTiltRearPin);

  pinMode(laserFrontPin, OUTPUT);
  pinMode(laserRearPin, OUTPUT);
  pinMode(buzzerPin, OUTPUT);

  pinMode(frontTrig, OUTPUT);
  pinMode(frontEcho, INPUT);
  pinMode(rearTrig, OUTPUT);
  pinMode(rearEcho, INPUT);

  Serial.begin(9600);

  u8g2.begin();
  u8g2.clearBuffer();
  u8g2.sendBuffer();
}

// ================= LOOP =================
void loop() {
  unsigned long now = millis();

  // ---- PAN ----
  if (now - lastPanTime > panInterval) {
    lastPanTime = now;
    panAngle += panDir;
    if (panAngle <= panMin || panAngle >= panMax) panDir *= -1;
    panServo.write(panAngle);
  }

  // ---- TILT ----
  if (now - lastTiltTime > tiltInterval) {
    lastTiltTime = now;
    tiltAngle += tiltDir;
    if (tiltAngle <= tiltMin || tiltAngle >= tiltMax) tiltDir *= -1;
    frontServo.write(tiltAngle);
    rearServo.write(tiltAngle);
  }

  static long fd = -1, rd = -1;

  // ---- ULTRASONIC ----
  if (now - lastUltraTime > ultraInterval) {
    lastUltraTime = now;
    fd = readDistance(frontTrig, frontEcho);
    rd = readDistance(rearTrig, rearEcho);

    // ===== RADAR SERIAL =====
    Serial.print("F:");
    Serial.print(panAngle);
    Serial.print(",");
    Serial.print(tiltAngle);
    Serial.print(",");
    Serial.println(fd);

    Serial.print("R:");
    Serial.print(panAngle + 180);
    Serial.print(",");
    Serial.print(tiltAngle);
    Serial.print(",");
    Serial.println(rd);
  }

  bool frontEnemy = fd > 0 && fd <= 50;
  bool rearEnemy  = rd > 0 && rd <= 50;

  // ---- LASER ----
  digitalWrite(laserFrontPin, frontEnemy);
  digitalWrite(laserRearPin, rearEnemy);

  if (frontEnemy) aimLaserFront(panAngle, tiltAngle, fd);
  if (rearEnemy)  aimLaserRear(panAngle, tiltAngle, rd);

  // ---- SIREN ----
  if (frontEnemy || rearEnemy) {
    long d = frontEnemy ? fd : rd;
    d <= 20 ? siren() : tone(buzzerPin, 1200);
  } else {
    noTone(buzzerPin);
  }

  // ===== LASER ANGLE SERIAL (ADD ONLY) =====
  Serial.print("LF:");
  Serial.print(laserFrontPanAngle);
  Serial.print(",");
  Serial.println(laserFrontTiltAngle);

  Serial.print("LR:");
  Serial.print(laserRearPanAngle);
  Serial.print(",");
  Serial.println(laserRearTiltAngle);

  // ---- OLED ----
  if (now - lastOledTime > oledInterval) {
    lastOledTime = now;
    updateOLED(frontEnemy ? fd : rd, frontEnemy);
  }
}
