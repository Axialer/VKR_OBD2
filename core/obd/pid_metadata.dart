class PidMetaExtended {
  final String pid;
  final String name;
  final String? unit;
  final double? min;
  final double? max;
  final double? normalMin;
  final double? normalMax;
  final bool isExtended;

  PidMetaExtended({
    required this.pid,
    required this.name,
    this.unit,
    this.min,
    this.max,
    this.normalMin,
    this.normalMax,
    this.isExtended = false,
  });
}

final Map<String, PidMetaExtended> allPidMeta = {
  // PID 00–0F
  '00': PidMetaExtended(pid: '00', name: 'Поддерживаемые PID 01–20', isExtended: false),
  '01': PidMetaExtended(pid: '01', name: 'Статус мониторов, MIL', isExtended: false),
  '02': PidMetaExtended(pid: '02', name: 'Сохранённые DTC', isExtended: false),
  '03': PidMetaExtended(pid: '03', name: 'Статус топливной системы', isExtended: false),
  '04': PidMetaExtended(pid: '04', name: 'Расчётная нагрузка двигателя', unit: '%', min: 0, max: 100, normalMin: 0, normalMax: 100, isExtended: false),
  '05': PidMetaExtended(pid: '05', name: 'Температура охлаждающей жидкости', unit: '°C', min: -40, max: 215, normalMin: 70, normalMax: 120, isExtended: false),
  '06': PidMetaExtended(pid: '06', name: 'Кратковременная коррекция топлива (Bank 1)', unit: '%', min: -100, max: 100, normalMin: -10, normalMax: 10, isExtended: false),
  '07': PidMetaExtended(pid: '07', name: 'Долговременная коррекция топлива (Bank 1)', unit: '%', min: -100, max: 100, normalMin: -15, normalMax: 15, isExtended: false),
  '08': PidMetaExtended(pid: '08', name: 'Кратковременная коррекция топлива (Bank 2)', unit: '%', min: -100, max: 100, normalMin: -10, normalMax: 10, isExtended: false),
  '09': PidMetaExtended(pid: '09', name: 'Долговременная коррекция топлива (Bank 2)', unit: '%', min: -100, max: 100, normalMin: -15, normalMax: 15, isExtended: false),
  '0A': PidMetaExtended(pid: '0A', name: 'Давление топлива', unit: 'кПа', min: 0, max: 765, normalMin: 200, normalMax: 400, isExtended: false),
  '0B': PidMetaExtended(pid: '0B', name: 'Давление во впускном коллекторе', unit: 'кПа', min: 0, max: 255, normalMin: 20, normalMax: 80, isExtended: false),
  '0C': PidMetaExtended(pid: '0C', name: 'Обороты двигателя', unit: 'об/мин', min: 0, max: 16383, normalMin: 700, normalMax: 3000, isExtended: false),
  '0D': PidMetaExtended(pid: '0D', name: 'Скорость автомобиля', unit: 'км/ч', min: 0, max: 255, normalMin: 0, normalMax: 200, isExtended: false),
  '0E': PidMetaExtended(pid: '0E', name: 'Угол опережения зажигания', unit: '°', min: -64, max: 63.5, normalMin: -10, normalMax: 30, isExtended: false),
  '0F': PidMetaExtended(pid: '0F', name: 'Температура всасываемого воздуха', unit: '°C', min: -40, max: 215, normalMin: -10, normalMax: 50, isExtended: false),

  // PID 10–1F
  '10': PidMetaExtended(pid: '10', name: 'Массовый расход воздуха (MAF)', unit: 'г/с', min: 0, max: 655.35, normalMin: 2, normalMax: 300, isExtended: false),
  '11': PidMetaExtended(pid: '11', name: 'Положение дроссельной заслонки', unit: '%', min: 0, max: 100, normalMin: 0, normalMax: 30, isExtended: false),
  '12': PidMetaExtended(pid: '12', name: 'Состояние управляемого вторичного воздуха', isExtended: false),
  '13': PidMetaExtended(pid: '13', name: 'Наличие датчиков кислорода', isExtended: false),
  '14': PidMetaExtended(pid: '14', name: 'O2 Bank1 Sensor1', unit: 'мВ', min: 0, max: 1.275, normalMin: 0.1, normalMax: 0.9, isExtended: false),
  '15': PidMetaExtended(pid: '15', name: 'O2 Bank1 Sensor2', unit: 'мВ', isExtended: false),
  '16': PidMetaExtended(pid: '16', name: 'O2 Bank1 Sensor3', unit: 'мВ', isExtended: false),
  '17': PidMetaExtended(pid: '17', name: 'O2 Bank1 Sensor4', unit: 'мВ', isExtended: false),
  '18': PidMetaExtended(pid: '18', name: 'O2 Bank2 Sensor1', unit: 'мВ', isExtended: false),
  '19': PidMetaExtended(pid: '19', name: 'O2 Bank2 Sensor2', unit: 'мВ', isExtended: false),
  '1A': PidMetaExtended(pid: '1A', name: 'O2 Bank2 Sensor3', unit: 'мВ', isExtended: false),
  '1B': PidMetaExtended(pid: '1B', name: 'O2 Bank2 Sensor4', unit: 'мВ', isExtended: false),
  '1C': PidMetaExtended(pid: '1C', name: 'Стандарт OBD', isExtended: false),
  '1D': PidMetaExtended(pid: '1D', name: 'Наличие O2 датчиков (расширенный)', isExtended: false),
  '1E': PidMetaExtended(pid: '1E', name: 'Состояние вспомогательного входа', isExtended: false),
  '1F': PidMetaExtended(pid: '1F', name: 'Время работы двигателя', unit: 'с', min: 0, max: 65535, normalMin: 0, normalMax: 10000, isExtended: false),

  // PID 20–2F
  '20': PidMetaExtended(pid: '20', name: 'Поддерживаемые PID 21–40', isExtended: false),
  '21': PidMetaExtended(pid: '21', name: 'Дистанция с горящей MIL', unit: 'км', min: 0, max: 65535, isExtended: false),
  '22': PidMetaExtended(pid: '22', name: 'Относительное давление в топливной рампе', unit: 'кПа', min: -32768, max: 32767, isExtended: false),
  '23': PidMetaExtended(pid: '23', name: 'Давление топливной рампы (дизель/GDI)', unit: 'кПа', min: 0, max: 65535, isExtended: false),
  '24': PidMetaExtended(pid: '24', name: 'Эквивалентное отношение (O2 Sensor)', unit: 'λ', isExtended: true),
  '25': PidMetaExtended(pid: '25', name: 'O2 Sensor ток', unit: 'мА', isExtended: true),
  '26': PidMetaExtended(pid: '26', name: 'Ток O2 Sensor (Bank1 Sensor1)', unit: 'мА', isExtended: true),
  '27': PidMetaExtended(pid: '27', name: 'Ток O2 Sensor (Bank1 Sensor2)', unit: 'мА', isExtended: true),
  '28': PidMetaExtended(pid: '28', name: 'Ток O2 Sensor (Bank2 Sensor1)', unit: 'мА', isExtended: true),
  '29': PidMetaExtended(pid: '29', name: 'Ток O2 Sensor (Bank2 Sensor2)', unit: 'мА', isExtended: true),
  '2A': PidMetaExtended(pid: '2A', name: 'Напряжение O2 Sensor (Bank1 Sensor1)', unit: 'В', isExtended: true),
  '2B': PidMetaExtended(pid: '2B', name: 'Напряжение O2 Sensor (Bank1 Sensor2)', unit: 'В', isExtended: true),
  '2C': PidMetaExtended(pid: '2C', name: 'Напряжение O2 Sensor (Bank2 Sensor1)', unit: 'В', isExtended: true),
  '2D': PidMetaExtended(pid: '2D', name: 'Напряжение O2 Sensor (Bank2 Sensor2)', unit: 'В', isExtended: true),
  '2E': PidMetaExtended(pid: '2E', name: 'Температура катализатора (Bank1 Sensor1)', unit: '°C', isExtended: true),
  '2F': PidMetaExtended(pid: '2F', name: 'Температура катализатора (Bank2 Sensor1)', unit: '°C', isExtended: true),

  // PID 30–3F
  '30': PidMetaExtended(pid: '30', name: 'Температура катализатора (Bank1 Sensor2)', unit: '°C', isExtended: true),
  '31': PidMetaExtended(pid: '31', name: 'Температура катализатора (Bank2 Sensor2)', unit: '°C', isExtended: true),
  '32': PidMetaExtended(pid: '32', name: 'Поддерживаемые PID 41–60', isExtended: false),
  '33': PidMetaExtended(pid: '33', name: 'Статус мониторов в текущем цикле', isExtended: false),
  '34': PidMetaExtended(pid: '34', name: 'Напряжение блока управления', unit: 'В', min: 0, max: 65.535, normalMin: 11.5, normalMax: 15.0, isExtended: false),
  '35': PidMetaExtended(pid: '35', name: 'Абсолютная нагрузка', unit: '%', min: 0, max: 257, isExtended: false),
  '36': PidMetaExtended(pid: '36', name: 'Командуемый коэффициент λ (lambda)', unit: 'λ', min: 0, max: 2, normalMin: 0.95, normalMax: 1.05, isExtended: false),
  '37': PidMetaExtended(pid: '37', name: 'Относительное положение дросселя', unit: '%', min: 0, max: 100, isExtended: false),
  '38': PidMetaExtended(pid: '38', name: 'Температура наружного воздуха', unit: '°C', min: -40, max: 215, isExtended: false),
  '39': PidMetaExtended(pid: '39', name: 'Абсолютное положение дросселя B', unit: '%', isExtended: false),
  '3A': PidMetaExtended(pid: '3A', name: 'Абсолютное положение дросселя C', unit: '%', isExtended: false),
  '3B': PidMetaExtended(pid: '3B', name: 'Положение педали акселератора D', unit: '%', isExtended: false),
  '3C': PidMetaExtended(pid: '3C', name: 'Положение педали акселератора E', unit: '%', isExtended: false),
  '3D': PidMetaExtended(pid: '3D', name: 'Положение педали акселератора F', unit: '%', isExtended: false),
  '3E': PidMetaExtended(pid: '3E', name: 'Командуемое положение дросселя', unit: '%', isExtended: false),
  '3F': PidMetaExtended(pid: '3F', name: 'Время работы с горящей MIL', unit: 'с', isExtended: false),

  // PID 40–4F
  '40': PidMetaExtended(pid: '40', name: 'Время с момента очистки кодов', unit: 'с', isExtended: false),
  '41': PidMetaExtended(pid: '41', name: 'Максимальные значения lambda/O2', isExtended: true),
  '42': PidMetaExtended(pid: '42', name: 'Максимум массового расхода воздуха', unit: 'г/с', isExtended: true),
  '43': PidMetaExtended(pid: '43', name: 'Тип топлива', isExtended: false),
  '44': PidMetaExtended(pid: '44', name: 'Процент этанола в топливе', unit: '%', min: 0, max: 100, isExtended: false),
  '45': PidMetaExtended(pid: '45', name: 'Абсолютное давление в системе EVAP', unit: 'кПа', isExtended: false),
  '46': PidMetaExtended(pid: '46', name: 'Давление в системе EVAP', unit: 'Па', isExtended: false),
  '47': PidMetaExtended(pid: '47', name: 'Кратковременная коррекция вторичных O2 (Bank1/3)', unit: '%', isExtended: true),
  '48': PidMetaExtended(pid: '48', name: 'Долговременная коррекция вторичных O2 (Bank1/3)', unit: '%', isExtended: true),
  '49': PidMetaExtended(pid: '49', name: 'Кратковременная коррекция вторичных O2 (Bank2/4)', unit: '%', isExtended: true),
  '4A': PidMetaExtended(pid: '4A', name: 'Долговременная коррекция вторичных O2 (Bank2/4)', unit: '%', isExtended: true),
  '4B': PidMetaExtended(pid: '4B', name: 'Абсолютное давление на топливной рампе', unit: 'кПа', isExtended: false),
  '4C': PidMetaExtended(pid: '4C', name: 'Относительное положение педали акселератора', unit: '%', isExtended: false),
  '4D': PidMetaExtended(pid: '4D', name: 'Остаток ресурса аккумулятора гибрида', unit: '%', isExtended: true),
  '4E': PidMetaExtended(pid: '4E', name: 'Температура масла двигателя', unit: '°C', min: -40, max: 215, isExtended: false),
  '4F': PidMetaExtended(pid: '4F', name: 'Угол топливоподачи', unit: '°', isExtended: false),

  // PID 50–5F
  '50': PidMetaExtended(pid: '50', name: 'Расход топлива двигателя', unit: 'л/ч', isExtended: false),
  '51': PidMetaExtended(pid: '51', name: 'Уровень экологических требований', isExtended: false),
  '52': PidMetaExtended(pid: '52', name: 'Поддерживаемые PID 61–80', isExtended: false),
  '53': PidMetaExtended(pid: '53', name: 'Требуемый момент двигателя', unit: 'Н·м', isExtended: false),
  '54': PidMetaExtended(pid: '54', name: 'Реальный момент двигателя', unit: 'Н·м', isExtended: false),
  '55': PidMetaExtended(pid: '55', name: 'Базовый момент (Engine reference torque)', unit: 'Н·м', isExtended: false),
  '5C': PidMetaExtended(pid: '5C', name: 'Температура масла двигателя (альтернатива)', unit: '°C', isExtended: false),
};