/**
 * 三轴步进电机控制程序
 * 硬件: Arduino + A4988 驱动板 × 3 + 28BYJ-48 步进电机 × 3
 * 功能: 独立控制 X、Y、Z 三个轴的步进电机
 */

// ========== X轴配置 ==========
const int X_DIR_PIN = 2;     // 方向引脚
const int X_STEP_PIN = 3;    // 脉冲引脚
const int X_ENABLE_PIN = 4;  // 使能引脚

// ========== Y轴配置 ==========
const int Y_DIR_PIN = 5;
const int Y_STEP_PIN = 6;
const int Y_ENABLE_PIN = 7;

// ========== Z轴配置 ==========
const int Z_DIR_PIN = 8;
const int Z_STEP_PIN = 9;
const int Z_ENABLE_PIN = 10;

// 电机参数
const int MICROSTEPS = 16;           // A4988 微步数（1, 2, 4, 8, 16）
const int STEPS_PER_REV = 200;       // 步进电机每转步数
const int MOTOR_STEPS = STEPS_PER_REV * MICROSTEPS;  // 总步数

// 速度控制（单位：微秒，越小速度越快）
int pulse_delay = 500;  // 脉冲间隔（调整这个值来改变速度）

/**
 * 步进电机结构体
 */
struct Stepper {
  int dir_pin;
  int step_pin;
  int enable_pin;
  int direction;  // 1: 正方向, -1: 反方向
};

Stepper motorX = {X_DIR_PIN, X_STEP_PIN, X_ENABLE_PIN, 1};
Stepper motorY = {Y_DIR_PIN, Y_STEP_PIN, Y_ENABLE_PIN, 1};
Stepper motorZ = {Z_DIR_PIN, Z_STEP_PIN, Z_ENABLE_PIN, 1};

void setup() {
  Serial.begin(9600);
  
  // 初始化X轴引脚
  pinMode(motorX.dir_pin, OUTPUT);
  pinMode(motorX.step_pin, OUTPUT);
  pinMode(motorX.enable_pin, OUTPUT);
  
  // 初始化Y轴引脚
  pinMode(motorY.dir_pin, OUTPUT);
  pinMode(motorY.step_pin, OUTPUT);
  pinMode(motorY.enable_pin, OUTPUT);
  
  // 初始化Z轴引脚
  pinMode(motorZ.dir_pin, OUTPUT);
  pinMode(motorZ.step_pin, OUTPUT);
  pinMode(motorZ.enable_pin, OUTPUT);
  
  // 使能电机
  digitalWrite(motorX.enable_pin, LOW);
  digitalWrite(motorY.enable_pin, LOW);
  digitalWrite(motorZ.enable_pin, LOW);
  
  Serial.println("三轴步进电机系统已初始化");
  Serial.println("命令格式: <轴><步数><速度>");
  Serial.println("示例: X 100 500 (X轴转100步,延迟500us)");
}

void loop() {
  // 演示程序：各轴顺序旋转
  Serial.println("X轴正向旋转1圈...");
  rotate_motor(motorX, MOTOR_STEPS, pulse_delay);
  delay(500);
  
  Serial.println("Y轴正向旋转1圈...");
  rotate_motor(motorY, MOTOR_STEPS, pulse_delay);
  delay(500);
  
  Serial.println("Z轴正向旋转1圈...");
  rotate_motor(motorZ, MOTOR_STEPS, pulse_delay);
  delay(500);
  
  // 反向旋转
  Serial.println("X轴反向旋转1圈...");
  motorX.direction = -1;
  rotate_motor(motorX, MOTOR_STEPS, pulse_delay);
  motorX.direction = 1;
  delay(500);
  
  // 读取串口命令
  if (Serial.available() > 0) {
    handle_serial_command();
  }
}

/**
 * 电机旋转函数
 * @param motor 电机结构体
 * @param steps 转数
 * @param delay_us 脉冲延迟（微秒）
 */
void rotate_motor(Stepper &motor, int steps, int delay_us) {
  // 设置方向
  if (motor.direction > 0) {
    digitalWrite(motor.dir_pin, HIGH);  // 正向
  } else {
    digitalWrite(motor.dir_pin, LOW);   // 反向
  }
  
  delayMicroseconds(10);  // 方向稳定时间
  
  // 发送脉冲
  for (int i = 0; i < steps; i++) {
    digitalWrite(motor.step_pin, HIGH);
    delayMicroseconds(delay_us / 2);
    digitalWrite(motor.step_pin, LOW);
    delayMicroseconds(delay_us / 2);
  }
}

/**
 * 处理串口命令
 * 格式: X 100 500 (轴 步数 延迟)
 */
void handle_serial_command() {
  String input = Serial.readStringUntil('\n');
  input.trim();
  
  char axis = input.charAt(0);
  int steps = 0;
  int delay_us = pulse_delay;
  
  // 解析步数
  int space1 = input.indexOf(' ');
  if (space1 > 0) {
    steps = input.substring(space1 + 1).toInt();
  }
  
  // 解析延迟
  int space2 = input.indexOf(' ', space1 + 1);
  if (space2 > 0) {
    delay_us = input.substring(space2 + 1).toInt();
  }
  
  Serial.print("命令: ");
  Serial.print(axis);
  Serial.print(" ");
  Serial.print(steps);
  Serial.print(" ");
  Serial.println(delay_us);
  
  switch(axis) {
    case 'X':
    case 'x':
      rotate_motor(motorX, steps, delay_us);
      Serial.println("X轴旋转完成");
      break;
    case 'Y':
    case 'y':
      rotate_motor(motorY, steps, delay_us);
      Serial.println("Y轴旋转完成");
      break;
    case 'Z':
    case 'z':
      rotate_motor(motorZ, steps, delay_us);
      Serial.println("Z轴旋转完成");
      break;
    default:
      Serial.println("未知命令");
  }
}

/**
 * 停止电机（禁用输出）
 */
void disable_motors() {
  digitalWrite(motorX.enable_pin, HIGH);
  digitalWrite(motorY.enable_pin, HIGH);
  digitalWrite(motorZ.enable_pin, HIGH);
  Serial.println("电机已禁用");
}

/**
 * 启用电机
 */
void enable_motors() {
  digitalWrite(motorX.enable_pin, LOW);
  digitalWrite(motorY.enable_pin, LOW);
  digitalWrite(motorZ.enable_pin, LOW);
  Serial.println("电机已启用");
}
