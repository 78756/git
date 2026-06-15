/**
 * StepperMotor.h - 步进电机库
 * 简化三轴步进电机控制
 */

#ifndef STEPPER_MOTOR_H
#define STEPPER_MOTOR_H

#include <Arduino.h>

class StepperMotor {
private:
  int dir_pin;
  int step_pin;
  int enable_pin;
  int direction;
  int pulse_delay;
  
public:
  // 构造函数
  StepperMotor(int dir, int step, int en) 
    : dir_pin(dir), step_pin(step), enable_pin(en), 
      direction(1), pulse_delay(500) {
    init();
  }
  
  // 初始化引脚
  void init() {
    pinMode(dir_pin, OUTPUT);
    pinMode(step_pin, OUTPUT);
    pinMode(enable_pin, OUTPUT);
    disable();
  }
  
  // 启用电机
  void enable() {
    digitalWrite(enable_pin, LOW);
  }
  
  // 禁用电机
  void disable() {
    digitalWrite(enable_pin, HIGH);
  }
  
  // 设置方向
  void setDirection(int dir) {
    direction = (dir > 0) ? 1 : -1;
    digitalWrite(dir_pin, (direction > 0) ? HIGH : LOW);
    delayMicroseconds(10);
  }
  
  // 设置脉冲延迟
  void setPulseDelay(int delay_us) {
    pulse_delay = delay_us;
  }
  
  // 转动指定步数
  void step(int steps) {
    for (int i = 0; i < abs(steps); i++) {
      digitalWrite(step_pin, HIGH);
      delayMicroseconds(pulse_delay / 2);
      digitalWrite(step_pin, LOW);
      delayMicroseconds(pulse_delay / 2);
    }
  }
  
  // 正向旋转
  void forward(int steps) {
    setDirection(1);
    step(steps);
  }
  
  // 反向旋转
  void backward(int steps) {
    setDirection(-1);
    step(steps);
  }
  
  // 旋转指定圈数（基于 3200 步/圈）
  void rotate(float revolutions, int delay_us = 0) {
    if (delay_us > 0) {
      setPulseDelay(delay_us);
    }
    int total_steps = (int)(revolutions * 3200);
    step(total_steps);
  }
};

#endif
