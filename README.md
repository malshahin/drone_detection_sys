# Arduino Drone Detection & Laser Tracking System

This project is a self-developed educational prototype of a short-range drone detection and laser tracking air defence simulation system. I designed and implemented this system to understand how radar scanning, target detection, servo control, geometric correction, and real-time visualization work together in a coordinated embedded system.

The system uses dual ultrasonic radar units (front and rear) mounted on pan-tilt servos to continuously scan the environment. When an object enters the defined threat range, the system automatically aligns a laser module toward the detected target and activates an alert mechanism. A Processing-based GUI visualizes the radar sweep, target position, laser alignment angles, and system status in real time.

## Key Features

1. Dual radar scanning (front and rear)
2. Automatic laser targeting with geometric offset correction
3. Real-time radar visualization using Processing
4. OLED threat status display (SAFE / SERIOUS / DANGER)
5. Air attack siren alert system
6. Trigonometric correction for physical laser offset
7. Average 95% detection accuracy in controlled indoor testing

## How It Works

1. The ultrasonic sensors continuously measure object distance.
2. Pan and tilt servos scan from 0° to 180°.
3. Distance and angle data are sent to Arduino.
4. If an object is detected within 50 cm, it is classified as a threat.
5. The laser targeting module calculates corrected angles based on physical mounting offsets.
6. The Processing GUI visualizes radar sweep and target tracking in real time.

The geometric correction ensures that the laser beam aligns accurately even though it is mounted:
1. 6 cm below the radar sensor
2. 5 cm forward
3. Rear laser offset 2 cm to the left

Without this correction, the laser would miss the target due to physical displacement.

## System Components

Hardware:
1. Arduino Uno 3
2. 2x HC-SR04 ultrasonic sensors
3. 4x micro servos (radar pan/tilt)
4. 4x micro servos (laser pan/tilt)
5. Laser modules
6. OLED display
7. Buzzer

Software:
1. Arduino IDE
2. Processing (Radar GUI)

## Project Purpose

This project is built strictly for educational and research purposes. It is designed to simulate short-range drone detection and tracking behavior in a controlled environment. It does not classify friendly vs hostile targets and does not use high-power laser systems.

## Repository Structure

1. /Arduino_Code → Complete embedded system code
2. /Processing_Code → Real-time radar visualization code
3. /images → Hardware setup and GUI screenshots
4. /README.md → Full documentation

## Results

In controlled indoor testing:

1. Front radar detection accuracy ≈ 96%
2. Rear radar detection accuracy ≈ 94%
3. Overall average accuracy ≈ 95%

## Future Improvements

1. Computer vision-based drone classification
2. RF signal detection integration
3. AI-based threat identification
4. Long-range sensor upgrade (LiDAR)
5. PID-based smoother tracking system

[For more detiled show my article on medium.](https://medium.com/@malshahin/building-my-own-drone-detection-laser-tracking-air-defense-system-using-arduino-28266ce7fbb9)
