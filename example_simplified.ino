/**
 * 简化示例 - 使用 StepperMotor 库
 * 更简洁的三轴控制
 */

#include "StepperMotor.h"

// 创建三个电机对象
StepperMotor motorX(2, 3, 4);    // DIR=2, STEP=3, ENABLE=4
StepperMotor motorY(5, 6, 7);    // DIR=5, STEP=6, ENABLE=7
StepperMotor motorZ(8, 9, 10);   // DIR=8, STEP=9, ENABLE=10

void setup() {
  Serial.begin(9600);
  
  // 启用所有电机
  motorX.enable();
  motorY.enable();
  motorZ.enable();
  
  // 设置脉冲延迟（500 微秒）
  motorX.setPulseDelay(500);
  motorY.setPulseDelay(500);
  motorZ.setPulseDelay(500);
  
  Serial.println("三轴步进电机系统已就绪");
  Serial.println("命令: X 1 500 (X轴转1圈，延迟500us)");
}

void loop() {
  // 演示：各轴顺序转动
  Serial.println("演示开始...");
  
  // X轴转1圈
  motorX.rotate(1.0);
  delay(500);
  
  // Y轴转2圈
  motorY.rotate(2.0);
  delay(500);
  
  // Z轴转1.5圈，速度加快
  motorZ.rotate(1.5, 300);  // 延迟300us，速度更快
  delay(500);
  
  // 反向旋转
  motorX.backward(3200);  // 反向转1圈
  delay(500);
  
  Serial.println("演示完成，等待命令...");
  delay(2000);
  
  // 读取串口命令
  if (Serial.available() > 0) {
    handle_command();
  }
}

/**
 * 处理串口命令
 * 格式: X 1 500  (轴 圈数 延迟)
 */
void handle_command() {
  String input = Serial.readStringUntil('\n');
  input.trim();
  
  if (input.length() < 1) return;
  
  char axis = input.charAt(0);
  
  // 解析圈数
  int space1 = input.indexOf(' ');
  float revolutions = 1.0;
  if (space1 > 0) {
    revolutions = input.substring(space1 + 1).toFloat();
  }
  
  // 解析延迟
  int space2 = input.indexOf(' ', space1 + 1);
  int delay_us = 500;
  if (space2 > 0) {
    delay_us = input.substring(space2 + 1).toInt();
  }
  
  Serial.print("执行: ");
  Serial.print(axis);
  Serial.print(" 转 ");
  Serial.print(revolutions);
  Serial.print(" 圈，延迟 ");
  Serial.print(delay_us);
  Serial.println(" us");
  
  switch(axis) {
    case 'X':
    case 'x':
      motorX.setPulseDelay(delay_us);
      motorX.rotate(revolutions);
      Serial.println("✓ X轴完成");
      break;
      
    case 'Y':
    case 'y':
      motorY.setPulseDelay(delay_us);
      motorY.rotate(revolutions);
      Serial.println("✓ Y轴完成");
      break;
      
    case 'Z':
    case 'z':
      motorZ.setPulseDelay(delay_us);
      motorZ.rotate(revolutions);
      Serial.println("✓ Z轴完成");
      break;
      
    case 'R':
    case 'r': {
      // 快速归位：所有轴反向转10圈
      motorX.setPulseDelay(300);
      motorY.setPulseDelay(300);
      motorZ.setPulseDelay(300);
      motorX.backward(32000);
      motorY.backward(32000);
      motorZ.backward(32000);
      Serial.println("✓ 所有轴已归位");
      break;
    }
      
    case 'D':
    case 'd':
      // 禁用所有电机
      motorX.disable();
      motorY.disable();
      motorZ.disable();
      Serial.println("✓ 所有电机已禁用");
      break;
      
    case 'E':
    case 'e':
      // 启用所有电机
      motorX.enable();
      motorY.enable();
      motorZ.enable();
      Serial.println("✓ 所有电机已启用");
      break;
      
    default:
      print_help();
  }
}

void print_help() {
  Serial.println("\n========== 帮助信息 ==========");
  Serial.println("X/Y/Z <圈数> [延迟] - 转动轴");
  Serial.println("  示例: X 1 500    (X轴转1圈，延迟500us)");
  Serial.println("R                  - 所有轴反向转10圈（归位）");
  Serial.println("D                  - 禁用所有电机");
  Serial.println("E                  - 启用所有电机");
  Serial.println("H                  - 显示此帮助");
  Serial.println("=============================\n");
}
