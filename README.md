# iALU's ADD and SUB operations verification and code/functional coverage
## 1. Info
1. Т.к. данный тестбенч проверяет лишь операции ADD и SUB, логика которых является комбинационной схемой,  тактовый сигнал используется исключительно для удобного отображения значений на временной диаграмме,  т.е формирует временные задержки между командами для возможности проверки этих самых значений. Сброс модулю не требуется.
2. Тоже самое касалось сигналов test1_done, test2_done: использовались только для удобства отладки тестбенча.
3. Хардкод был необоснованным, удалён.
## 2. Code coverage:

![report png](https://github.com/Shuregg/ialu-verification/assets/47576452/9a53cfeb-b433-4926-b971-fc28bb2bb558)

## 3. Functional coverage:

![fcover png](https://github.com/Shuregg/ialu-verification/assets/47576452/5434d5aa-8cae-4fd3-8590-54aabd3e0543)

Check next files for more information:
code_cover_report.txt[1], 
func_cover_report.txt[2], 
general_coverage_report_details.txt[3]

[1] (https://github.com/Shuregg/ialu-verification/blob/develop/coverage_reports/code_cover_report.txt)

[2] (https://github.com/Shuregg/ialu-verification/blob/develop/coverage_reports/func_cover_report.txt)

[3] (https://github.com/Shuregg/ialu-verification/blob/develop/coverage_reports/general_coverage_report_details.txt)
