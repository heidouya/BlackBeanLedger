/**
 * 自定义数字键盘组件
 * 支持：0-9、小数点、删除、加减运算符、完成
 */
@Component
export struct CustomKeypad {
  @Link expression: string;
  @Link preview: string;
  onComplete?: (value: number) => void;

  build() {
    Column() {
      // 第 1 行: 1 2 3 ⌫
      Row() {
        this.keyBtn('1', () => this.onDigit('1'))
        this.keyBtn('2', () => this.onDigit('2'))
        this.keyBtn('3', () => this.onDigit('3'))
        this.keyBtn('⌫', () => this.onDelete(), $r('app.color.keypad_secondary_btn_bg'))
      }
      // 第 2 行: 4 5 6 +
      Row() {
        this.keyBtn('4', () => this.onDigit('4'))
        this.keyBtn('5', () => this.onDigit('5'))
        this.keyBtn('6', () => this.onDigit('6'))
        this.keyBtn('+', () => this.onOperator('+'), $r('app.color.keypad_secondary_btn_bg'))
      }
      // 第 3 行: 7 8 9 -
      Row() {
        this.keyBtn('7', () => this.onDigit('7'))
        this.keyBtn('8', () => this.onDigit('8'))
        this.keyBtn('9', () => this.onDigit('9'))
        this.keyBtn('-', () => this.onOperator('-'), $r('app.color.keypad_secondary_btn_bg'))
      }
      // 第 4 行: . 0 完成(×2)
      Row() {
        this.keyBtn('.', () => this.onDecimal())
        this.keyBtn('0', () => this.onDigit('0'))
        Button('完成')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.card_background'))
          .layoutWeight(2)
          .height(52)
          .margin(4)
          .borderRadius(8)
          .backgroundColor($r('app.color.dark_card_background'))
          .onClick(() => this.onDone())
      }
    }
    .width('100%')
    .backgroundColor($r('app.color.keypad_background'))
    .padding({ top: 8, bottom: 16, left: 8, right: 8 })
  }

  @Builder
  keyBtn(label: string, onClick: () => void, bgColor?: ResourceColor) {
    Button(label)
      .fontSize(24)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('app.color.keypad_btn_text'))
      .layoutWeight(1)
      .height(52)
      .margin(4)
      .borderRadius(8)
      .backgroundColor(bgColor ?? $r('app.color.keypad_btn_background'))
      .onClick(onClick)
  }

  // ==================== 键盘事件处理 ====================

  private onDigit(digit: string): void {
    this.expression += digit;
    this.updatePreview();
  }

  private onOperator(op: string): void {
    if (this.expression === '') {
      return;
    }
    const lastChar = this.expression[this.expression.length - 1];
    if (lastChar === '+' || lastChar === '-') {
      this.expression = this.expression.substring(0, this.expression.length - 1) + op;
    } else if (lastChar === '.') {
      this.expression = this.expression.substring(0, this.expression.length - 1) + op;
    } else {
      this.expression += op;
    }
    this.preview = '';
  }

  private onDecimal(): void {
    let lastOpIndex = -1;
    for (let i = this.expression.length - 1; i >= 0; i--) {
      if (this.expression[i] === '+' || this.expression[i] === '-') {
        lastOpIndex = i;
        break;
      }
    }
    const currentNum = this.expression.substring(lastOpIndex + 1);
    if (currentNum.includes('.')) {
      return;
    }
    if (currentNum === '') {
      this.expression += '0.';
    } else {
      this.expression += '.';
    }
    this.preview = '';
  }

  private onDelete(): void {
    if (this.expression.length > 0) {
      this.expression = this.expression.substring(0, this.expression.length - 1);
      this.updatePreview();
    }
  }

  private onDone(): void {
    let expr = this.expression;
    if (expr === '') {
      return;
    }
    while (expr.endsWith('+') || expr.endsWith('-') || expr.endsWith('.')) {
      expr = expr.substring(0, expr.length - 1);
    }
    if (expr === '') {
      return;
    }
    const result = this.evaluate(expr);
    this.onComplete?.(result);
  }

  private evaluate(expr: string): number {
    let result = 0;
    let currentNum = '';
    let currentOp = '+';

    for (let i = 0; i <= expr.length; i++) {
      const ch = i < expr.length ? expr[i] : '';
      if (ch === '+' || ch === '-' || i === expr.length) {
        const num = parseFloat(currentNum) || 0;
        if (currentOp === '+') {
          result += num;
        } else if (currentOp === '-') {
          result -= num;
        }
        currentOp = ch;
        currentNum = '';
      } else {
        currentNum += ch;
      }
    }
    return result;
  }

  private updatePreview(): void {
    const expr = this.expression;
    if (expr === '' || expr.endsWith('+') || expr.endsWith('-') || expr.endsWith('.')) {
      this.preview = '';
      return;
    }
    if (expr.includes('+') || expr.includes('-')) {
      const result = this.evaluate(expr);
      this.preview = this.formatAmount(result);
    } else {
      this.preview = '';
    }
  }

  private formatAmount(n: number): string {
    let s = n.toFixed(2);
    if (s.includes('.')) {
      s = s.replace(/\.?0+$/, '');
    }
    return s;
  }
}
