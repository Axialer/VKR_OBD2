// lib/core/data/car_metadata.dart

/// Метаданные поколения автомобиля
class CarGenerationMeta {
  final String name;
  final int yearStart;
  final int? yearEnd; // null = актуальное поколение

  const CarGenerationMeta({
    required this.name,
    required this.yearStart,
    this.yearEnd,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'years_start': yearStart,
    'years_end': yearEnd,
  };
}

/// Метаданные модели автомобиля
class CarModelMeta {
  final String name;
  final List<CarGenerationMeta> generations;

  const CarModelMeta({
    required this.name,
    required this.generations,
  });
}

/// Метаданные марки автомобиля
class CarBrandMeta {
  final String name;
  final String? logo;
  final List<CarModelMeta> models;

  const CarBrandMeta({
    required this.name,
    this.logo,
    required this.models,
  });
}

/// 🚗 Все доступные марки автомобилей
/// Добавляйте новые марки в конец списка
const allCarBrands = <CarBrandMeta>[
  // ==================== РОССИЙСКИЕ БРЕНДЫ ====================
  CarBrandMeta(
    name: 'Lada',
    models: [
      CarModelMeta(
        name: '2101',
        generations: [CarGenerationMeta(name: '2101', yearStart: 1970, yearEnd: 1988)],
      ),
      CarModelMeta(
        name: '2106',
        generations: [CarGenerationMeta(name: '2106', yearStart: 1976, yearEnd: 2006)],
      ),
      CarModelMeta(
        name: '2107',
        generations: [CarGenerationMeta(name: '2107', yearStart: 1982, yearEnd: 2012)],
      ),
      CarModelMeta(
        name: 'Niva',
        generations: [
          CarGenerationMeta(name: '2121', yearStart: 1977, yearEnd: 1994),
          CarGenerationMeta(name: '21213/21214', yearStart: 1994, yearEnd: null),
          CarGenerationMeta(name: 'Niva Travel', yearStart: 2020, yearEnd: null),
        ],
      ),
      CarModelMeta(
        name: 'Niva Urban',
        generations: [CarGenerationMeta(name: 'Urban', yearStart: 2014, yearEnd: null)],
      ),
      CarModelMeta(
        name: 'Samara (2108/2109/21099)',
        generations: [
          CarGenerationMeta(name: '2108', yearStart: 1984, yearEnd: 2013),
          CarGenerationMeta(name: '2109', yearStart: 1987, yearEnd: 2011),
          CarGenerationMeta(name: '21099', yearStart: 1990, yearEnd: 2011),
        ],
      ),
      CarModelMeta(
        name: '110/111/112',
        generations: [CarGenerationMeta(name: '110 family', yearStart: 1995, yearEnd: 2009)],
      ),
      CarModelMeta(
        name: 'Priora',
        generations: [
          CarGenerationMeta(name: '2170', yearStart: 2007, yearEnd: 2015),
          CarGenerationMeta(name: '2170 rest', yearStart: 2013, yearEnd: 2018),
        ],
      ),
      CarModelMeta(
        name: 'Kalina',
        generations: [
          CarGenerationMeta(name: '1117/1118/1119', yearStart: 2004, yearEnd: 2013),
          CarGenerationMeta(name: '2190/2192/2194', yearStart: 2013, yearEnd: 2018),
        ],
      ),
      CarModelMeta(
        name: 'Granta',
        generations: [
          CarGenerationMeta(name: '2190 sedan/liftback', yearStart: 2011, yearEnd: 2018),
          CarGenerationMeta(name: '2190 restyling', yearStart: 2018, yearEnd: null),
        ],
      ),
      CarModelMeta(
        name: 'Vesta',
        generations: [
          CarGenerationMeta(name: 'Sedan/SW', yearStart: 2015, yearEnd: 2022),
          CarGenerationMeta(name: 'NG (New Generation)', yearStart: 2022, yearEnd: null),
        ],
      ),
      CarModelMeta(
        name: 'XRAY',
        generations: [CarGenerationMeta(name: 'XRAY', yearStart: 2015, yearEnd: 2022)],
      ),
      CarModelMeta(
        name: 'Largus',
        generations: [
          CarGenerationMeta(name: 'KS0/RS0', yearStart: 2012, yearEnd: 2021),
          CarGenerationMeta(name: 'Largus FL', yearStart: 2021, yearEnd: null),
        ],
      ),
      CarModelMeta(name: 'Aura', generations: [CarGenerationMeta(name: 'Aura', yearStart: 2022, yearEnd: null)]),
    ],
  ),

  CarBrandMeta(
    name: 'UAZ',
    models: [
      CarModelMeta(
        name: 'Patriot',
        generations: [
          CarGenerationMeta(name: '3163', yearStart: 2005, yearEnd: 2014),
          CarGenerationMeta(name: '3163 rest', yearStart: 2014, yearEnd: null),
        ],
      ),
      CarModelMeta(
        name: 'Hunter',
        generations: [CarGenerationMeta(name: '31519/315195', yearStart: 2003, yearEnd: null)],
      ),
      CarModelMeta(
        name: 'Pickup',
        generations: [CarGenerationMeta(name: '2360', yearStart: 2008, yearEnd: null)],
      ),
      CarModelMeta(name: 'Buhanka', generations: [CarGenerationMeta(name: '2206/3741/3909', yearStart: 1965, yearEnd: null)]),
    ],
  ),

  CarBrandMeta(
    name: 'GAZ',
    models: [
      CarModelMeta(name: 'Volga', generations: [
        CarGenerationMeta(name: '21', yearStart: 1956, yearEnd: 1970),
        CarGenerationMeta(name: '24', yearStart: 1970, yearEnd: 1992),
        CarGenerationMeta(name: '3102/3110', yearStart: 1982, yearEnd: 2009),
      ]),
      CarModelMeta(name: 'Gazel', generations: [
        CarGenerationMeta(name: '3302', yearStart: 1994, yearEnd: 2003),
        CarGenerationMeta(name: 'Business/Next', yearStart: 2003, yearEnd: null),
      ]),
      CarModelMeta(name: 'Sobol', generations: [CarGenerationMeta(name: '2752', yearStart: 1998, yearEnd: null)]),
    ],
  ),

  // ==================== ЯПОНСКИЕ БРЕНДЫ ====================
  CarBrandMeta(
    name: 'Toyota',
    models: [
      CarModelMeta(name: 'Camry', generations: [
        CarGenerationMeta(name: 'XV10', yearStart: 1991, yearEnd: 1996),
        CarGenerationMeta(name: 'XV20', yearStart: 1996, yearEnd: 2001),
        CarGenerationMeta(name: 'XV30', yearStart: 2001, yearEnd: 2006),
        CarGenerationMeta(name: 'XV40', yearStart: 2006, yearEnd: 2011),
        CarGenerationMeta(name: 'XV50', yearStart: 2011, yearEnd: 2017),
        CarGenerationMeta(name: 'XV70', yearStart: 2017, yearEnd: 2024),
        CarGenerationMeta(name: 'XV80', yearStart: 2024, yearEnd: null),
      ]),
      CarModelMeta(name: 'Corolla', generations: [
        CarGenerationMeta(name: 'E80', yearStart: 1983, yearEnd: 1987),
        CarGenerationMeta(name: 'E90', yearStart: 1987, yearEnd: 1991),
        CarGenerationMeta(name: 'E100', yearStart: 1991, yearEnd: 1995),
        CarGenerationMeta(name: 'E110', yearStart: 1995, yearEnd: 2000),
        CarGenerationMeta(name: 'E120', yearStart: 2000, yearEnd: 2006),
        CarGenerationMeta(name: 'E140/E150', yearStart: 2006, yearEnd: 2013),
        CarGenerationMeta(name: 'E160/E170', yearStart: 2013, yearEnd: 2019),
        CarGenerationMeta(name: 'E210', yearStart: 2019, yearEnd: null),
      ]),
      CarModelMeta(name: 'RAV4', generations: [
        CarGenerationMeta(name: 'XA10', yearStart: 1994, yearEnd: 2000),
        CarGenerationMeta(name: 'XA20', yearStart: 2000, yearEnd: 2005),
        CarGenerationMeta(name: 'XA30', yearStart: 2005, yearEnd: 2012),
        CarGenerationMeta(name: 'XA40', yearStart: 2012, yearEnd: 2019),
        CarGenerationMeta(name: 'XA50', yearStart: 2019, yearEnd: null),
      ]),
      CarModelMeta(name: 'Land Cruiser', generations: [
        CarGenerationMeta(name: 'J40', yearStart: 1960, yearEnd: 1984),
        CarGenerationMeta(name: 'J60', yearStart: 1980, yearEnd: 1989),
        CarGenerationMeta(name: 'J70', yearStart: 1984, yearEnd: null),
        CarGenerationMeta(name: 'J80', yearStart: 1989, yearEnd: 1997),
        CarGenerationMeta(name: 'J100', yearStart: 1998, yearEnd: 2007),
        CarGenerationMeta(name: 'J200', yearStart: 2007, yearEnd: 2021),
        CarGenerationMeta(name: 'J300', yearStart: 2021, yearEnd: null),
      ]),
      CarModelMeta(name: 'Land Cruiser Prado', generations: [
        CarGenerationMeta(name: 'J90', yearStart: 1996, yearEnd: 2002),
        CarGenerationMeta(name: 'J120', yearStart: 2002, yearEnd: 2009),
        CarGenerationMeta(name: 'J150', yearStart: 2009, yearEnd: 2023),
        CarGenerationMeta(name: 'J250', yearStart: 2023, yearEnd: null),
      ]),
      CarModelMeta(name: 'Highlander', generations: [
        CarGenerationMeta(name: 'XU20', yearStart: 2000, yearEnd: 2007),
        CarGenerationMeta(name: 'XU40', yearStart: 2007, yearEnd: 2013),
        CarGenerationMeta(name: 'XU50', yearStart: 2013, yearEnd: 2019),
        CarGenerationMeta(name: 'XU70', yearStart: 2019, yearEnd: null),
      ]),
      CarModelMeta(name: 'Yaris', generations: [
        CarGenerationMeta(name: 'XP10', yearStart: 1999, yearEnd: 2005),
        CarGenerationMeta(name: 'XP90', yearStart: 2005, yearEnd: 2011),
        CarGenerationMeta(name: 'XP130', yearStart: 2011, yearEnd: 2020),
        CarGenerationMeta(name: 'XP210', yearStart: 2020, yearEnd: null),
      ]),
      CarModelMeta(name: 'Prius', generations: [
        CarGenerationMeta(name: 'XW10', yearStart: 1997, yearEnd: 2003),
        CarGenerationMeta(name: 'XW20', yearStart: 2003, yearEnd: 2009),
        CarGenerationMeta(name: 'XW30', yearStart: 2009, yearEnd: 2015),
        CarGenerationMeta(name: 'XW50', yearStart: 2015, yearEnd: 2023),
        CarGenerationMeta(name: 'XW60', yearStart: 2023, yearEnd: null),
      ]),
      CarModelMeta(name: 'Avensis', generations: [
        CarGenerationMeta(name: 'T220', yearStart: 1997, yearEnd: 2003),
        CarGenerationMeta(name: 'T250', yearStart: 2003, yearEnd: 2009),
        CarGenerationMeta(name: 'T270', yearStart: 2009, yearEnd: 2018),
      ]),
      CarModelMeta(name: 'Hilux', generations: [
        CarGenerationMeta(name: 'N140-N170', yearStart: 1997, yearEnd: 2004),
        CarGenerationMeta(name: 'AN10-AN20', yearStart: 2004, yearEnd: 2015),
        CarGenerationMeta(name: 'AN120-AN130', yearStart: 2015, yearEnd: null),
      ]),
    ],
  ),

  CarBrandMeta(
    name: 'Nissan',
    models: [
      CarModelMeta(name: 'Almera', generations: [
        CarGenerationMeta(name: 'N15', yearStart: 1995, yearEnd: 2000),
        CarGenerationMeta(name: 'N16', yearStart: 2000, yearEnd: 2006),
        CarGenerationMeta(name: 'G15 (RUS)', yearStart: 2012, yearEnd: 2018),
      ]),
      CarModelMeta(name: 'Teana', generations: [
        CarGenerationMeta(name: 'J31', yearStart: 2003, yearEnd: 2008),
        CarGenerationMeta(name: 'J32', yearStart: 2008, yearEnd: 2014),
        CarGenerationMeta(name: 'L33', yearStart: 2014, yearEnd: 2020),
      ]),
      CarModelMeta(name: 'X-Trail', generations: [
        CarGenerationMeta(name: 'T30', yearStart: 2000, yearEnd: 2007),
        CarGenerationMeta(name: 'T31', yearStart: 2007, yearEnd: 2014),
        CarGenerationMeta(name: 'T32', yearStart: 2014, yearEnd: 2022),
        CarGenerationMeta(name: 'T33', yearStart: 2022, yearEnd: null),
      ]),
      CarModelMeta(name: 'Qashqai', generations: [
        CarGenerationMeta(name: 'J10', yearStart: 2006, yearEnd: 2013),
        CarGenerationMeta(name: 'J11', yearStart: 2013, yearEnd: 2021),
        CarGenerationMeta(name: 'J12', yearStart: 2021, yearEnd: null),
      ]),
      CarModelMeta(name: 'Patrol', generations: [
        CarGenerationMeta(name: 'Y60', yearStart: 1987, yearEnd: 1997),
        CarGenerationMeta(name: 'Y61', yearStart: 1997, yearEnd: 2010),
        CarGenerationMeta(name: 'Y62', yearStart: 2010, yearEnd: null),
      ]),
      CarModelMeta(name: 'Pathfinder', generations: [
        CarGenerationMeta(name: 'R50', yearStart: 1995, yearEnd: 2004),
        CarGenerationMeta(name: 'R51', yearStart: 2004, yearEnd: 2012),
        CarGenerationMeta(name: 'R52', yearStart: 2012, yearEnd: 2022),
        CarGenerationMeta(name: 'R53', yearStart: 2022, yearEnd: null),
      ]),
      CarModelMeta(name: 'Murano', generations: [
        CarGenerationMeta(name: 'Z50', yearStart: 2002, yearEnd: 2007),
        CarGenerationMeta(name: 'Z51', yearStart: 2007, yearEnd: 2014),
        CarGenerationMeta(name: 'Z52', yearStart: 2014, yearEnd: null),
      ]),
      CarModelMeta(name: 'Note', generations: [
        CarGenerationMeta(name: 'E11', yearStart: 2004, yearEnd: 2013),
        CarGenerationMeta(name: 'E12', yearStart: 2013, yearEnd: 2021),
        CarGenerationMeta(name: 'E13', yearStart: 2021, yearEnd: null),
      ]),
      CarModelMeta(name: 'Juke', generations: [
        CarGenerationMeta(name: 'F15', yearStart: 2010, yearEnd: 2019),
        CarGenerationMeta(name: 'F16', yearStart: 2019, yearEnd: null),
      ]),
      CarModelMeta(name: 'GT-R', generations: [
        CarGenerationMeta(name: 'R35', yearStart: 2007, yearEnd: null),
      ]),
    ],
  ),

  CarBrandMeta(
    name: 'Honda',
    models: [
      CarModelMeta(name: 'Civic', generations: [
        CarGenerationMeta(name: 'EK/EM', yearStart: 1995, yearEnd: 2000),
        CarGenerationMeta(name: 'EP/ES/EU', yearStart: 2000, yearEnd: 2005),
        CarGenerationMeta(name: 'FD/FA/FG', yearStart: 2005, yearEnd: 2011),
        CarGenerationMeta(name: 'FB/FG', yearStart: 2011, yearEnd: 2017),
        CarGenerationMeta(name: 'FL/FC', yearStart: 2017, yearEnd: 2021),
        CarGenerationMeta(name: 'FE', yearStart: 2021, yearEnd: null),
      ]),
      CarModelMeta(name: 'Accord', generations: [
        CarGenerationMeta(name: 'CG/CH/CL', yearStart: 1998, yearEnd: 2002),
        CarGenerationMeta(name: 'CL/CM', yearStart: 2002, yearEnd: 2008),
        CarGenerationMeta(name: 'CU/CP', yearStart: 2008, yearEnd: 2013),
        CarGenerationMeta(name: 'CR/CT', yearStart: 2013, yearEnd: 2017),
        CarGenerationMeta(name: 'CV', yearStart: 2017, yearEnd: null),
      ]),
      CarModelMeta(name: 'CR-V', generations: [
        CarGenerationMeta(name: 'RD', yearStart: 1995, yearEnd: 2001),
        CarGenerationMeta(name: 'RD4-RD9', yearStart: 2001, yearEnd: 2006),
        CarGenerationMeta(name: 'RE', yearStart: 2006, yearEnd: 2012),
        CarGenerationMeta(name: 'RM', yearStart: 2012, yearEnd: 2016),
        CarGenerationMeta(name: 'RW', yearStart: 2016, yearEnd: 2022),
        CarGenerationMeta(name: 'RT', yearStart: 2022, yearEnd: null),
      ]),
      CarModelMeta(name: 'Pilot', generations: [
        CarGenerationMeta(name: 'YF1-YF4', yearStart: 2002, yearEnd: 2008),
        CarGenerationMeta(name: 'YF5-YF6', yearStart: 2008, yearEnd: 2015),
        CarGenerationMeta(name: 'YF7-YF8', yearStart: 2015, yearEnd: 2022),
        CarGenerationMeta(name: 'YF9', yearStart: 2022, yearEnd: null),
      ]),
      CarModelMeta(name: 'HR-V', generations: [
        CarGenerationMeta(name: 'GH', yearStart: 1998, yearEnd: 2006),
        CarGenerationMeta(name: 'RU', yearStart: 2014, yearEnd: 2021),
        CarGenerationMeta(name: 'UZ', yearStart: 2021, yearEnd: null),
      ]),
      CarModelMeta(name: 'Fit/Jazz', generations: [
        CarGenerationMeta(name: 'GD', yearStart: 2001, yearEnd: 2007),
        CarGenerationMeta(name: 'GE', yearStart: 2007, yearEnd: 2013),
        CarGenerationMeta(name: 'GK', yearStart: 2013, yearEnd: 2020),
        CarGenerationMeta(name: 'GR', yearStart: 2020, yearEnd: null),
      ]),
    ],
  ),

  CarBrandMeta(
    name: 'Mazda',
    models: [
      CarModelMeta(name: '3 (Axela)', generations: [
        CarGenerationMeta(name: 'BK', yearStart: 2003, yearEnd: 2009),
        CarGenerationMeta(name: 'BL', yearStart: 2009, yearEnd: 2013),
        CarGenerationMeta(name: 'BM/BN', yearStart: 2013, yearEnd: 2019),
        CarGenerationMeta(name: 'BP', yearStart: 2019, yearEnd: null),
      ]),
      CarModelMeta(name: '6 (Atenza)', generations: [
        CarGenerationMeta(name: 'GG/GY', yearStart: 2002, yearEnd: 2007),
        CarGenerationMeta(name: 'GH', yearStart: 2007, yearEnd: 2012),
        CarGenerationMeta(name: 'GJ/GL', yearStart: 2012, yearEnd: 2021),
        CarGenerationMeta(name: 'GJ facelift', yearStart: 2021, yearEnd: null),
      ]),
      CarModelMeta(name: 'CX-5', generations: [
        CarGenerationMeta(name: 'KE', yearStart: 2011, yearEnd: 2017),
        CarGenerationMeta(name: 'KF', yearStart: 2017, yearEnd: null),
      ]),
      CarModelMeta(name: 'CX-30', generations: [CarGenerationMeta(name: 'DM', yearStart: 2019, yearEnd: null)]),
      CarModelMeta(name: 'CX-7', generations: [CarGenerationMeta(name: 'ER', yearStart: 2006, yearEnd: 2012)]),
      CarModelMeta(name: 'CX-9', generations: [
        CarGenerationMeta(name: 'TB', yearStart: 2006, yearEnd: 2015),
        CarGenerationMeta(name: 'TC', yearStart: 2015, yearEnd: null),
      ]),
      CarModelMeta(name: 'RX-8', generations: [CarGenerationMeta(name: 'SE', yearStart: 2003, yearEnd: 2012)]),
      CarModelMeta(name: 'MX-5', generations: [
        CarGenerationMeta(name: 'NA', yearStart: 1989, yearEnd: 1997),
        CarGenerationMeta(name: 'NB', yearStart: 1998, yearEnd: 2005),
        CarGenerationMeta(name: 'NC', yearStart: 2005, yearEnd: 2015),
        CarGenerationMeta(name: 'ND', yearStart: 2015, yearEnd: null),
      ]),
    ],
  ),

  CarBrandMeta(
    name: 'Mitsubishi',
    models: [
      CarModelMeta(name: 'Lancer', generations: [
        CarGenerationMeta(name: 'CJ/CK/CM/CP', yearStart: 1995, yearEnd: 2000),
        CarGenerationMeta(name: 'CS/CT', yearStart: 2000, yearEnd: 2007),
        CarGenerationMeta(name: 'CY/CZ', yearStart: 2007, yearEnd: 2017),
      ]),
      CarModelMeta(name: 'Outlander', generations: [
        CarGenerationMeta(name: 'ZG/ZH', yearStart: 2001, yearEnd: 2006),
        CarGenerationMeta(name: 'ZJ/ZL/ZK', yearStart: 2006, yearEnd: 2012),
        CarGenerationMeta(name: 'GG/GF', yearStart: 2012, yearEnd: 2021),
        CarGenerationMeta(name: 'GN', yearStart: 2021, yearEnd: null),
      ]),
      CarModelMeta(name: 'Pajero', generations: [
        CarGenerationMeta(name: 'V20/V40', yearStart: 1991, yearEnd: 1999),
        CarGenerationMeta(name: 'V60/V70', yearStart: 1999, yearEnd: 2006),
        CarGenerationMeta(name: 'V80/V90', yearStart: 2006, yearEnd: 2021),
      ]),
      CarModelMeta(name: 'Pajero Sport', generations: [
        CarGenerationMeta(name: 'K90', yearStart: 1996, yearEnd: 2008),
        CarGenerationMeta(name: 'KH/KG', yearStart: 2008, yearEnd: 2015),
        CarGenerationMeta(name: 'KS/KT', yearStart: 2015, yearEnd: null),
      ]),
      CarModelMeta(name: 'ASX', generations: [
        CarGenerationMeta(name: 'GA/GW', yearStart: 2010, yearEnd: 2019),
        CarGenerationMeta(name: 'GA facelift', yearStart: 2019, yearEnd: null),
      ]),
      CarModelMeta(name: 'Eclipse Cross', generations: [CarGenerationMeta(name: 'YA/YB', yearStart: 2017, yearEnd: null)]),
      CarModelMeta(name: 'L200/Triton', generations: [
        CarGenerationMeta(name: 'K74T/K75T', yearStart: 1996, yearEnd: 2006),
        CarGenerationMeta(name: 'KB/KT', yearStart: 2006, yearEnd: 2015),
        CarGenerationMeta(name: 'KR/KS', yearStart: 2015, yearEnd: null),
      ]),
    ],
  ),

  CarBrandMeta(
    name: 'Subaru',
    models: [
      CarModelMeta(name: 'Impreza', generations: [
        CarGenerationMeta(name: 'GC/GF', yearStart: 1992, yearEnd: 2000),
        CarGenerationMeta(name: 'GD/GG', yearStart: 2000, yearEnd: 2007),
        CarGenerationMeta(name: 'GE/GH/GR', yearStart: 2007, yearEnd: 2011),
        CarGenerationMeta(name: 'GP/GJ', yearStart: 2011, yearEnd: 2016),
        CarGenerationMeta(name: 'GT', yearStart: 2016, yearEnd: null),
      ]),
      CarModelMeta(name: 'Legacy', generations: [
        CarGenerationMeta(name: 'BC/BF', yearStart: 1989, yearEnd: 1993),
        CarGenerationMeta(name: 'BD/BG', yearStart: 1993, yearEnd: 1998),
        CarGenerationMeta(name: 'BE/BH', yearStart: 1998, yearEnd: 2003),
        CarGenerationMeta(name: 'BL/BP', yearStart: 2003, yearEnd: 2009),
        CarGenerationMeta(name: 'BM/BR', yearStart: 2009, yearEnd: 2014),
        CarGenerationMeta(name: 'BN/BS', yearStart: 2014, yearEnd: null),
      ]),
      CarModelMeta(name: 'Outback', generations: [
        CarGenerationMeta(name: 'BG', yearStart: 1994, yearEnd: 1998),
        CarGenerationMeta(name: 'BH', yearStart: 1998, yearEnd: 2003),
        CarGenerationMeta(name: 'BP', yearStart: 2003, yearEnd: 2009),
        CarGenerationMeta(name: 'BR', yearStart: 2009, yearEnd: 2014),
        CarGenerationMeta(name: 'BS', yearStart: 2014, yearEnd: 2021),
        CarGenerationMeta(name: 'BT', yearStart: 2021, yearEnd: null),
      ]),
      CarModelMeta(name: 'Forester', generations: [
        CarGenerationMeta(name: 'SF', yearStart: 1997, yearEnd: 2002),
        CarGenerationMeta(name: 'SG', yearStart: 2002, yearEnd: 2007),
        CarGenerationMeta(name: 'SH', yearStart: 2007, yearEnd: 2012),
        CarGenerationMeta(name: 'SJ', yearStart: 2012, yearEnd: 2018),
        CarGenerationMeta(name: 'SK', yearStart: 2018, yearEnd: null),
      ]),
      CarModelMeta(name: 'XV/Crosstrek', generations: [
        CarGenerationMeta(name: 'GP', yearStart: 2011, yearEnd: 2017),
        CarGenerationMeta(name: 'GT', yearStart: 2017, yearEnd: null),
      ]),
      CarModelMeta(name: 'WRX/STI', generations: [
        CarGenerationMeta(name: 'GC/GF', yearStart: 1992, yearEnd: 2000),
        CarGenerationMeta(name: 'GD/GG', yearStart: 2000, yearEnd: 2007),
        CarGenerationMeta(name: 'GR/GV', yearStart: 2007, yearEnd: 2014),
        CarGenerationMeta(name: 'VA', yearStart: 2014, yearEnd: 2021),
        CarGenerationMeta(name: 'VB', yearStart: 2021, yearEnd: null),
      ]),
    ],
  ),

  CarBrandMeta(
    name: 'Lexus',
    models: [
      CarModelMeta(name: 'ES', generations: [
        CarGenerationMeta(name: 'XV10', yearStart: 1991, yearEnd: 1996),
        CarGenerationMeta(name: 'XV20', yearStart: 1996, yearEnd: 2001),
        CarGenerationMeta(name: 'XV30', yearStart: 2001, yearEnd: 2006),
        CarGenerationMeta(name: 'XV40', yearStart: 2006, yearEnd: 2012),
        CarGenerationMeta(name: 'XV60', yearStart: 2012, yearEnd: 2018),
        CarGenerationMeta(name: 'XV70', yearStart: 2018, yearEnd: null),
      ]),
      CarModelMeta(name: 'RX', generations: [
        CarGenerationMeta(name: 'XU10', yearStart: 1998, yearEnd: 2003),
        CarGenerationMeta(name: 'XU30', yearStart: 2003, yearEnd: 2009),
        CarGenerationMeta(name: 'AL10', yearStart: 2009, yearEnd: 2015),
        CarGenerationMeta(name: 'AL20', yearStart: 2015, yearEnd: 2022),
        CarGenerationMeta(name: 'AL30', yearStart: 2022, yearEnd: null),
      ]),
      CarModelMeta(name: 'NX', generations: [
        CarGenerationMeta(name: 'AZ10', yearStart: 2014, yearEnd: 2021),
        CarGenerationMeta(name: 'AZ20', yearStart: 2021, yearEnd: null),
      ]),
      CarModelMeta(name: 'UX', generations: [CarGenerationMeta(name: 'MZAA', yearStart: 2018, yearEnd: null)]),
      CarModelMeta(name: 'GX', generations: [
        CarGenerationMeta(name: 'J120', yearStart: 2002, yearEnd: 2009),
        CarGenerationMeta(name: 'J150', yearStart: 2009, yearEnd: 2023),
        CarGenerationMeta(name: 'J250', yearStart: 2023, yearEnd: null),
      ]),
      CarModelMeta(name: 'LX', generations: [
        CarGenerationMeta(name: 'J80', yearStart: 1995, yearEnd: 1997),
        CarGenerationMeta(name: 'J100', yearStart: 1998, yearEnd: 2007),
        CarGenerationMeta(name: 'J200', yearStart: 2007, yearEnd: 2021),
        CarGenerationMeta(name: 'J300', yearStart: 2021, yearEnd: null),
      ]),
      CarModelMeta(name: 'LS', generations: [
        CarGenerationMeta(name: 'XF10', yearStart: 1989, yearEnd: 1994),
        CarGenerationMeta(name: 'XF20', yearStart: 1994, yearEnd: 2000),
        CarGenerationMeta(name: 'XF30', yearStart: 2000, yearEnd: 2006),
        CarGenerationMeta(name: 'XF40', yearStart: 2006, yearEnd: 2017),
        CarGenerationMeta(name: 'XF50', yearStart: 2017, yearEnd: null),
      ]),
    ],
  ),

  // ==================== КОРЕЙСКИЕ БРЕНДЫ ====================
  CarBrandMeta(
    name: 'Hyundai',
    models: [
      CarModelMeta(name: 'Solaris', generations: [
        CarGenerationMeta(name: 'RB', yearStart: 2010, yearEnd: 2017),
        CarGenerationMeta(name: 'HC/RB facelift', yearStart: 2017, yearEnd: null),
      ]),
      CarModelMeta(name: 'Elantra', generations: [
        CarGenerationMeta(name: 'XD', yearStart: 2000, yearEnd: 2006),
        CarGenerationMeta(name: 'HD', yearStart: 2006, yearEnd: 2010),
        CarGenerationMeta(name: 'MD/UD', yearStart: 2010, yearEnd: 2016),
        CarGenerationMeta(name: 'AD', yearStart: 2016, yearEnd: 2020),
        CarGenerationMeta(name: 'CN7', yearStart: 2020, yearEnd: null),
      ]),
      CarModelMeta(name: 'Tucson', generations: [
        CarGenerationMeta(name: 'JM', yearStart: 2004, yearEnd: 2010),
        CarGenerationMeta(name: 'LM', yearStart: 2010, yearEnd: 2015),
        CarGenerationMeta(name: 'TL', yearStart: 2015, yearEnd: 2020),
        CarGenerationMeta(name: 'NX4', yearStart: 2020, yearEnd: null),
      ]),
      CarModelMeta(name: 'Santa Fe', generations: [
        CarGenerationMeta(name: 'SM', yearStart: 2000, yearEnd: 2006),
        CarGenerationMeta(name: 'CM', yearStart: 2006, yearEnd: 2012),
        CarGenerationMeta(name: 'DM', yearStart: 2012, yearEnd: 2018),
        CarGenerationMeta(name: 'TM', yearStart: 2018, yearEnd: 2023),
        CarGenerationMeta(name: 'MX5', yearStart: 2023, yearEnd: null),
      ]),
      CarModelMeta(name: 'Creta', generations: [
        CarGenerationMeta(name: 'GS', yearStart: 2016, yearEnd: 2021),
        CarGenerationMeta(name: 'SU2', yearStart: 2021, yearEnd: null),
      ]),
      CarModelMeta(name: 'Kona', generations: [
        CarGenerationMeta(name: 'OS', yearStart: 2017, yearEnd: 2023),
        CarGenerationMeta(name: 'SX2', yearStart: 2023, yearEnd: null),
      ]),
      CarModelMeta(name: 'Palisade', generations: [CarGenerationMeta(name: 'LX2', yearStart: 2018, yearEnd: null)]),
    ],
  ),

  CarBrandMeta(
    name: 'Kia',
    models: [
      CarModelMeta(name: 'Rio', generations: [
        CarGenerationMeta(name: 'DC', yearStart: 2000, yearEnd: 2005),
        CarGenerationMeta(name: 'JB', yearStart: 2005, yearEnd: 2011),
        CarGenerationMeta(name: 'UB', yearStart: 2011, yearEnd: 2017),
        CarGenerationMeta(name: 'FB/YB', yearStart: 2017, yearEnd: null),
      ]),
      CarModelMeta(name: 'Ceed', generations: [
        CarGenerationMeta(name: 'ED', yearStart: 2006, yearEnd: 2012),
        CarGenerationMeta(name: 'JD', yearStart: 2012, yearEnd: 2018),
        CarGenerationMeta(name: 'CD', yearStart: 2018, yearEnd: null),
      ]),
      CarModelMeta(name: 'Sportage', generations: [
        CarGenerationMeta(name: 'K00', yearStart: 1993, yearEnd: 2002),
        CarGenerationMeta(name: 'KM', yearStart: 2004, yearEnd: 2010),
        CarGenerationMeta(name: 'SL', yearStart: 2010, yearEnd: 2015),
        CarGenerationMeta(name: 'QL', yearStart: 2015, yearEnd: 2021),
        CarGenerationMeta(name: 'NQ5', yearStart: 2021, yearEnd: null),
      ]),
      CarModelMeta(name: 'Sorento', generations: [
        CarGenerationMeta(name: 'BL', yearStart: 2002, yearEnd: 2009),
        CarGenerationMeta(name: 'XM', yearStart: 2009, yearEnd: 2014),
        CarGenerationMeta(name: 'UM', yearStart: 2014, yearEnd: 2020),
        CarGenerationMeta(name: 'MQ4', yearStart: 2020, yearEnd: null),
      ]),
      CarModelMeta(name: 'Mohave', generations: [
        CarGenerationMeta(name: 'HM', yearStart: 2008, yearEnd: 2016),
        CarGenerationMeta(name: 'HM facelift', yearStart: 2016, yearEnd: null),
      ]),
      CarModelMeta(name: 'Telluride', generations: [CarGenerationMeta(name: 'UP', yearStart: 2019, yearEnd: null)]),
      CarModelMeta(name: 'EV6', generations: [CarGenerationMeta(name: 'CV', yearStart: 2021, yearEnd: null)]),
    ],
  ),

  CarBrandMeta(
    name: 'Genesis',
    models: [
      CarModelMeta(name: 'G70', generations: [CarGenerationMeta(name: 'IK', yearStart: 2017, yearEnd: null)]),
      CarModelMeta(name: 'G80', generations: [
        CarGenerationMeta(name: 'DH', yearStart: 2016, yearEnd: 2020),
        CarGenerationMeta(name: 'RG3', yearStart: 2020, yearEnd: null),
      ]),
      CarModelMeta(name: 'G90', generations: [
        CarGenerationMeta(name: 'EQ900', yearStart: 2016, yearEnd: 2020),
        CarGenerationMeta(name: 'RS3', yearStart: 2020, yearEnd: null),
      ]),
      CarModelMeta(name: 'GV70', generations: [CarGenerationMeta(name: 'JK1', yearStart: 2020, yearEnd: null)]),
      CarModelMeta(name: 'GV80', generations: [CarGenerationMeta(name: 'JX1', yearStart: 2020, yearEnd: null)]),
    ],
  ),

  // ==================== НЕМЕЦКИЕ БРЕНДЫ ====================
  CarBrandMeta(
    name: 'Volkswagen',
    models: [
      CarModelMeta(name: 'Golf', generations: [
        CarGenerationMeta(name: 'Mk1', yearStart: 1974, yearEnd: 1983),
        CarGenerationMeta(name: 'Mk2', yearStart: 1983, yearEnd: 1991),
        CarGenerationMeta(name: 'Mk3', yearStart: 1991, yearEnd: 1997),
        CarGenerationMeta(name: 'Mk4', yearStart: 1997, yearEnd: 2003),
        CarGenerationMeta(name: 'Mk5', yearStart: 2003, yearEnd: 2008),
        CarGenerationMeta(name: 'Mk6', yearStart: 2008, yearEnd: 2012),
        CarGenerationMeta(name: 'Mk7', yearStart: 2012, yearEnd: 2019),
        CarGenerationMeta(name: 'Mk8', yearStart: 2019, yearEnd: null),
      ]),
      CarModelMeta(name: 'Passat', generations: [
        CarGenerationMeta(name: 'B1-B2', yearStart: 1973, yearEnd: 1988),
        CarGenerationMeta(name: 'B3-B4', yearStart: 1988, yearEnd: 1996),
        CarGenerationMeta(name: 'B5', yearStart: 1996, yearEnd: 2005),
        CarGenerationMeta(name: 'B6-B7', yearStart: 2005, yearEnd: 2014),
        CarGenerationMeta(name: 'B8', yearStart: 2014, yearEnd: null),
      ]),
      CarModelMeta(name: 'Polo', generations: [
        CarGenerationMeta(name: '6N/6KV', yearStart: 1994, yearEnd: 2001),
        CarGenerationMeta(name: '9N', yearStart: 2001, yearEnd: 2009),
        CarGenerationMeta(name: '6R/6C', yearStart: 2009, yearEnd: 2017),
        CarGenerationMeta(name: 'AW', yearStart: 2017, yearEnd: null),
      ]),
      CarModelMeta(name: 'Tiguan', generations: [
        CarGenerationMeta(name: '5N', yearStart: 2007, yearEnd: 2016),
        CarGenerationMeta(name: 'AD1/5N FL', yearStart: 2016, yearEnd: 2023),
        CarGenerationMeta(name: 'B7', yearStart: 2023, yearEnd: null),
      ]),
      CarModelMeta(name: 'Touareg', generations: [
        CarGenerationMeta(name: '7L', yearStart: 2002, yearEnd: 2010),
        CarGenerationMeta(name: '7P', yearStart: 2010, yearEnd: 2018),
        CarGenerationMeta(name: 'CR', yearStart: 2018, yearEnd: null),
      ]),
      CarModelMeta(name: 'Jetta', generations: [
        CarGenerationMeta(name: 'Mk1-Mk2', yearStart: 1979, yearEnd: 1992),
        CarGenerationMeta(name: 'Vento/Bora', yearStart: 1992, yearEnd: 2005),
        CarGenerationMeta(name: 'Mk5-Mk6', yearStart: 2005, yearEnd: 2018),
        CarGenerationMeta(name: 'Mk7', yearStart: 2018, yearEnd: null),
      ]),
      CarModelMeta(name: 'Transporter', generations: [
        CarGenerationMeta(name: 'T1-T3', yearStart: 1950, yearEnd: 1992),
        CarGenerationMeta(name: 'T4', yearStart: 1990, yearEnd: 2003),
        CarGenerationMeta(name: 'T5', yearStart: 2003, yearEnd: 2015),
        CarGenerationMeta(name: 'T6/T6.1', yearStart: 2015, yearEnd: 2023),
        CarGenerationMeta(name: 'T7', yearStart: 2023, yearEnd: null),
      ]),
    ],
  ),

  CarBrandMeta(
    name: 'Audi',
    models: [
      CarModelMeta(name: 'A3', generations: [
        CarGenerationMeta(name: '8L', yearStart: 1996, yearEnd: 2003),
        CarGenerationMeta(name: '8P', yearStart: 2003, yearEnd: 2012),
        CarGenerationMeta(name: '8V', yearStart: 2012, yearEnd: 2020),
        CarGenerationMeta(name: '8Y', yearStart: 2020, yearEnd: null),
      ]),
      CarModelMeta(name: 'A4', generations: [
        CarGenerationMeta(name: 'B5', yearStart: 1994, yearEnd: 2001),
        CarGenerationMeta(name: 'B6/B7', yearStart: 2000, yearEnd: 2008),
        CarGenerationMeta(name: 'B8', yearStart: 2007, yearEnd: 2015),
        CarGenerationMeta(name: 'B9', yearStart: 2015, yearEnd: null),
      ]),
      CarModelMeta(name: 'A6', generations: [
        CarGenerationMeta(name: 'C4', yearStart: 1994, yearEnd: 1997),
        CarGenerationMeta(name: 'C5', yearStart: 1997, yearEnd: 2004),
        CarGenerationMeta(name: 'C6', yearStart: 2004, yearEnd: 2011),
        CarGenerationMeta(name: 'C7', yearStart: 2011, yearEnd: 2018),
        CarGenerationMeta(name: 'C8', yearStart: 2018, yearEnd: null),
      ]),
      CarModelMeta(name: 'A8', generations: [
        CarGenerationMeta(name: 'D2', yearStart: 1994, yearEnd: 2002),
        CarGenerationMeta(name: 'D3', yearStart: 2002, yearEnd: 2010),
        CarGenerationMeta(name: 'D4', yearStart: 2010, yearEnd: 2017),
        CarGenerationMeta(name: 'D5', yearStart: 2017, yearEnd: null),
      ]),
      CarModelMeta(name: 'Q3', generations: [
        CarGenerationMeta(name: '8U', yearStart: 2011, yearEnd: 2018),
        CarGenerationMeta(name: 'F3', yearStart: 2018, yearEnd: null),
      ]),
      CarModelMeta(name: 'Q5', generations: [
        CarGenerationMeta(name: '8R', yearStart: 2008, yearEnd: 2017),
        CarGenerationMeta(name: 'FY', yearStart: 2017, yearEnd: null),
      ]),
      CarModelMeta(name: 'Q7', generations: [
        CarGenerationMeta(name: '4L', yearStart: 2005, yearEnd: 2015),
        CarGenerationMeta(name: '4M', yearStart: 2015, yearEnd: null),
      ]),
      CarModelMeta(name: 'TT', generations: [
        CarGenerationMeta(name: '8N', yearStart: 1998, yearEnd: 2006),
        CarGenerationMeta(name: '8J', yearStart: 2006, yearEnd: 2014),
        CarGenerationMeta(name: 'FV/8S', yearStart: 2014, yearEnd: null),
      ]),
      CarModelMeta(name: 'e-tron', generations: [CarGenerationMeta(name: 'GE', yearStart: 2018, yearEnd: null)]),
    ],
  ),

  CarBrandMeta(
    name: 'BMW',
    models: [
      CarModelMeta(name: '3 Series', generations: [
        CarGenerationMeta(name: 'E30', yearStart: 1982, yearEnd: 1994),
        CarGenerationMeta(name: 'E36', yearStart: 1990, yearEnd: 2000),
        CarGenerationMeta(name: 'E46', yearStart: 1998, yearEnd: 2006),
        CarGenerationMeta(name: 'E90/E91/E92/E93', yearStart: 2005, yearEnd: 2013),
        CarGenerationMeta(name: 'F30/F31/F34/F35', yearStart: 2012, yearEnd: 2019),
        CarGenerationMeta(name: 'G20/G21', yearStart: 2019, yearEnd: null),
      ]),
      CarModelMeta(name: '5 Series', generations: [
        CarGenerationMeta(name: 'E12', yearStart: 1972, yearEnd: 1981),
        CarGenerationMeta(name: 'E28', yearStart: 1981, yearEnd: 1988),
        CarGenerationMeta(name: 'E34', yearStart: 1988, yearEnd: 1996),
        CarGenerationMeta(name: 'E39', yearStart: 1995, yearEnd: 2003),
        CarGenerationMeta(name: 'E60/E61', yearStart: 2003, yearEnd: 2010),
        CarGenerationMeta(name: 'F10/F11', yearStart: 2010, yearEnd: 2017),
        CarGenerationMeta(name: 'G30/G31', yearStart: 2017, yearEnd: null),
      ]),
      CarModelMeta(name: '7 Series', generations: [
        CarGenerationMeta(name: 'E23', yearStart: 1977, yearEnd: 1986),
        CarGenerationMeta(name: 'E32', yearStart: 1986, yearEnd: 1994),
        CarGenerationMeta(name: 'E38', yearStart: 1994, yearEnd: 2001),
        CarGenerationMeta(name: 'E65/E66', yearStart: 2001, yearEnd: 2008),
        CarGenerationMeta(name: 'F01/F02', yearStart: 2008, yearEnd: 2015),
        CarGenerationMeta(name: 'G11/G12', yearStart: 2015, yearEnd: null),
      ]),
      CarModelMeta(name: 'X3', generations: [
        CarGenerationMeta(name: 'E83', yearStart: 2003, yearEnd: 2010),
        CarGenerationMeta(name: 'F25', yearStart: 2010, yearEnd: 2017),
        CarGenerationMeta(name: 'G01', yearStart: 2017, yearEnd: null),
      ]),
      CarModelMeta(name: 'X5', generations: [
        CarGenerationMeta(name: 'E53', yearStart: 1999, yearEnd: 2006),
        CarGenerationMeta(name: 'E70', yearStart: 2006, yearEnd: 2013),
        CarGenerationMeta(name: 'F15', yearStart: 2013, yearEnd: 2018),
        CarGenerationMeta(name: 'G05', yearStart: 2018, yearEnd: null),
      ]),
      CarModelMeta(name: 'X7', generations: [CarGenerationMeta(name: 'G07', yearStart: 2018, yearEnd: null)]),
      CarModelMeta(name: 'Z4', generations: [
        CarGenerationMeta(name: 'E85/E86', yearStart: 2002, yearEnd: 2008),
        CarGenerationMeta(name: 'E89', yearStart: 2009, yearEnd: 2016),
        CarGenerationMeta(name: 'G29', yearStart: 2018, yearEnd: null),
      ]),
      CarModelMeta(name: 'i3', generations: [CarGenerationMeta(name: 'I01', yearStart: 2013, yearEnd: 2022)]),
      CarModelMeta(name: 'iX', generations: [CarGenerationMeta(name: 'I20', yearStart: 2021, yearEnd: null)]),
    ],
  ),

  CarBrandMeta(
    name: 'Mercedes-Benz',
    models: [
      CarModelMeta(name: 'C-Class', generations: [
        CarGenerationMeta(name: 'W202', yearStart: 1993, yearEnd: 2000),
        CarGenerationMeta(name: 'W203', yearStart: 2000, yearEnd: 2007),
        CarGenerationMeta(name: 'W204', yearStart: 2007, yearEnd: 2014),
        CarGenerationMeta(name: 'W205', yearStart: 2014, yearEnd: 2021),
        CarGenerationMeta(name: 'W206', yearStart: 2021, yearEnd: null),
      ]),
      CarModelMeta(name: 'E-Class', generations: [
        CarGenerationMeta(name: 'W124', yearStart: 1984, yearEnd: 1997),
        CarGenerationMeta(name: 'W210', yearStart: 1995, yearEnd: 2003),
        CarGenerationMeta(name: 'W211', yearStart: 2002, yearEnd: 2009),
        CarGenerationMeta(name: 'W212', yearStart: 2009, yearEnd: 2016),
        CarGenerationMeta(name: 'W213', yearStart: 2016, yearEnd: null),
      ]),
      CarModelMeta(name: 'S-Class', generations: [
        CarGenerationMeta(name: 'W140', yearStart: 1991, yearEnd: 1998),
        CarGenerationMeta(name: 'W220', yearStart: 1998, yearEnd: 2005),
        CarGenerationMeta(name: 'W221', yearStart: 2005, yearEnd: 2013),
        CarGenerationMeta(name: 'W222', yearStart: 2013, yearEnd: 2020),
        CarGenerationMeta(name: 'W223', yearStart: 2020, yearEnd: null),
      ]),
      CarModelMeta(name: 'GLC', generations: [
        CarGenerationMeta(name: 'X253', yearStart: 2015, yearEnd: 2022),
        CarGenerationMeta(name: 'X254', yearStart: 2022, yearEnd: null),
      ]),
      CarModelMeta(name: 'GLE', generations: [
        CarGenerationMeta(name: 'W166', yearStart: 2015, yearEnd: 2019),
        CarGenerationMeta(name: 'V167', yearStart: 2019, yearEnd: null),
      ]),
      CarModelMeta(name: 'GLS', generations: [
        CarGenerationMeta(name: 'X166', yearStart: 2015, yearEnd: 2019),
        CarGenerationMeta(name: 'X167', yearStart: 2019, yearEnd: null),
      ]),
      CarModelMeta(name: 'G-Class', generations: [
        CarGenerationMeta(name: 'W460/W461/W463', yearStart: 1979, yearEnd: 2018),
        CarGenerationMeta(name: 'W463A', yearStart: 2018, yearEnd: null),
      ]),
      CarModelMeta(name: 'A-Class', generations: [
        CarGenerationMeta(name: 'W168', yearStart: 1997, yearEnd: 2004),
        CarGenerationMeta(name: 'W169', yearStart: 2004, yearEnd: 2012),
        CarGenerationMeta(name: 'W176', yearStart: 2012, yearEnd: 2018),
        CarGenerationMeta(name: 'W177', yearStart: 2018, yearEnd: null),
      ]),
      CarModelMeta(name: 'EQC', generations: [CarGenerationMeta(name: 'N293', yearStart: 2019, yearEnd: null)]),
    ],
  ),

  CarBrandMeta(
    name: 'Opel',
    models: [
      CarModelMeta(name: 'Astra', generations: [
        CarGenerationMeta(name: 'F', yearStart: 1991, yearEnd: 1998),
        CarGenerationMeta(name: 'G', yearStart: 1998, yearEnd: 2004),
        CarGenerationMeta(name: 'H', yearStart: 2004, yearEnd: 2009),
        CarGenerationMeta(name: 'J', yearStart: 2009, yearEnd: 2015),
        CarGenerationMeta(name: 'K', yearStart: 2015, yearEnd: 2021),
        CarGenerationMeta(name: 'L', yearStart: 2021, yearEnd: null),
      ]),
      CarModelMeta(name: 'Corsa', generations: [
        CarGenerationMeta(name: 'A', yearStart: 1982, yearEnd: 1993),
        CarGenerationMeta(name: 'B', yearStart: 1993, yearEnd: 2000),
        CarGenerationMeta(name: 'C', yearStart: 2000, yearEnd: 2006),
        CarGenerationMeta(name: 'D', yearStart: 2006, yearEnd: 2014),
        CarGenerationMeta(name: 'E', yearStart: 2014, yearEnd: 2019),
        CarGenerationMeta(name: 'F', yearStart: 2019, yearEnd: null),
      ]),
      CarModelMeta(name: 'Insignia', generations: [
        CarGenerationMeta(name: 'A', yearStart: 2008, yearEnd: 2017),
        CarGenerationMeta(name: 'B', yearStart: 2017, yearEnd: null),
      ]),
      CarModelMeta(name: 'Mokka', generations: [
        CarGenerationMeta(name: 'A', yearStart: 2012, yearEnd: 2019),
        CarGenerationMeta(name: 'B', yearStart: 2019, yearEnd: null),
      ]),
      CarModelMeta(name: 'Grandland', generations: [CarGenerationMeta(name: 'X', yearStart: 2017, yearEnd: null)]),
    ],
  ),

  CarBrandMeta(
    name: 'Skoda',
    models: [
      CarModelMeta(name: 'Octavia', generations: [
        CarGenerationMeta(name: '1U', yearStart: 1996, yearEnd: 2010),
        CarGenerationMeta(name: '1Z/5E', yearStart: 2004, yearEnd: 2013),
        CarGenerationMeta(name: 'NE/5E FL', yearStart: 2013, yearEnd: 2020),
        CarGenerationMeta(name: 'NX', yearStart: 2020, yearEnd: null),
      ]),
      CarModelMeta(name: 'Fabia', generations: [
        CarGenerationMeta(name: '6Y', yearStart: 1999, yearEnd: 2007),
        CarGenerationMeta(name: '5J', yearStart: 2007, yearEnd: 2014),
        CarGenerationMeta(name: 'NJ', yearStart: 2014, yearEnd: 2021),
        CarGenerationMeta(name: 'PJ', yearStart: 2021, yearEnd: null),
      ]),
      CarModelMeta(name: 'Superb', generations: [
        CarGenerationMeta(name: '3U', yearStart: 2001, yearEnd: 2008),
        CarGenerationMeta(name: '3T', yearStart: 2008, yearEnd: 2015),
        CarGenerationMeta(name: '3V', yearStart: 2015, yearEnd: null),
      ]),
      CarModelMeta(name: 'Kodiaq', generations: [
        CarGenerationMeta(name: 'NS7', yearStart: 2016, yearEnd: 2024),
        CarGenerationMeta(name: 'NS7 FL', yearStart: 2024, yearEnd: null),
      ]),
      CarModelMeta(name: 'Karoq', generations: [CarGenerationMeta(name: 'NU7', yearStart: 2017, yearEnd: null)]),
      CarModelMeta(name: 'Scala', generations: [CarGenerationMeta(name: 'NW', yearStart: 2019, yearEnd: null)]),
      CarModelMeta(name: 'Kamiq', generations: [CarGenerationMeta(name: 'NW4', yearStart: 2019, yearEnd: null)]),
    ],
  ),

  CarBrandMeta(
    name: 'Porsche',
    models: [
      CarModelMeta(name: '911', generations: [
        CarGenerationMeta(name: '964', yearStart: 1989, yearEnd: 1994),
        CarGenerationMeta(name: '993', yearStart: 1994, yearEnd: 1998),
        CarGenerationMeta(name: '996', yearStart: 1997, yearEnd: 2005),
        CarGenerationMeta(name: '997', yearStart: 2004, yearEnd: 2012),
        CarGenerationMeta(name: '991', yearStart: 2011, yearEnd: 2019),
        CarGenerationMeta(name: '992', yearStart: 2019, yearEnd: null),
      ]),
      CarModelMeta(name: 'Cayenne', generations: [
        CarGenerationMeta(name: '9PA', yearStart: 2002, yearEnd: 2010),
        CarGenerationMeta(name: '92A', yearStart: 2010, yearEnd: 2017),
        CarGenerationMeta(name: 'PO536', yearStart: 2017, yearEnd: null),
      ]),
      CarModelMeta(name: 'Macan', generations: [
        CarGenerationMeta(name: '95B', yearStart: 2014, yearEnd: 2024),
        CarGenerationMeta(name: '95B EV', yearStart: 2024, yearEnd: null),
      ]),
      CarModelMeta(name: 'Panamera', generations: [
        CarGenerationMeta(name: '970', yearStart: 2009, yearEnd: 2016),
        CarGenerationMeta(name: 'G2', yearStart: 2016, yearEnd: null),
      ]),
      CarModelMeta(name: 'Taycan', generations: [CarGenerationMeta(name: 'J1', yearStart: 2019, yearEnd: null)]),
    ],
  ),

  // ==================== ФРАНЦУЗСКИЕ БРЕНДЫ ====================
  CarBrandMeta(
    name: 'Renault',
    models: [
      CarModelMeta(name: 'Logan', generations: [
        CarGenerationMeta(name: 'LS', yearStart: 2004, yearEnd: 2012),
        CarGenerationMeta(name: 'L2', yearStart: 2012, yearEnd: null),
      ]),
      CarModelMeta(name: 'Sandero', generations: [
        CarGenerationMeta(name: 'BS', yearStart: 2007, yearEnd: 2012),
        CarGenerationMeta(name: 'B2', yearStart: 2012, yearEnd: null),
      ]),
      CarModelMeta(name: 'Duster', generations: [
        CarGenerationMeta(name: 'HS', yearStart: 2010, yearEnd: 2015),
        CarGenerationMeta(name: 'HS facelift', yearStart: 2015, yearEnd: 2021),
        CarGenerationMeta(name: 'HM', yearStart: 2021, yearEnd: null),
      ]),
      CarModelMeta(name: 'Kaptur', generations: [
        CarGenerationMeta(name: 'H5A/H5B (RUS)', yearStart: 2016, yearEnd: 2021),
        CarGenerationMeta(name: 'HR', yearStart: 2021, yearEnd: null),
      ]),
      CarModelMeta(name: 'Megane', generations: [
        CarGenerationMeta(name: 'BA/DA', yearStart: 1995, yearEnd: 2002),
        CarGenerationMeta(name: 'LA/LB', yearStart: 2002, yearEnd: 2008),
        CarGenerationMeta(name: 'BZ', yearStart: 2008, yearEnd: 2016),
        CarGenerationMeta(name: 'BFB', yearStart: 2016, yearEnd: null),
      ]),
      CarModelMeta(name: 'Fluence', generations: [CarGenerationMeta(name: 'ZU', yearStart: 2009, yearEnd: 2016)]),
      CarModelMeta(name: 'Koleos', generations: [
        CarGenerationMeta(name: 'HY', yearStart: 2007, yearEnd: 2016),
        CarGenerationMeta(name: 'HZ', yearStart: 2016, yearEnd: null),
      ]),
      CarModelMeta(name: 'Arkana', generations: [CarGenerationMeta(name: 'HJ', yearStart: 2019, yearEnd: null)]),
    ],
  ),

  CarBrandMeta(
    name: 'Peugeot',
    models: [
      CarModelMeta(name: '308', generations: [
        CarGenerationMeta(name: 'T7', yearStart: 2007, yearEnd: 2013),
        CarGenerationMeta(name: 'T9', yearStart: 2013, yearEnd: 2021),
        CarGenerationMeta(name: 'P5', yearStart: 2021, yearEnd: null),
      ]),
      CarModelMeta(name: '3008', generations: [
        CarGenerationMeta(name: '0U', yearStart: 2008, yearEnd: 2016),
        CarGenerationMeta(name: 'P84', yearStart: 2016, yearEnd: 2023),
        CarGenerationMeta(name: 'P84 FL', yearStart: 2023, yearEnd: null),
      ]),
      CarModelMeta(name: '5008', generations: [
        CarGenerationMeta(name: '0U', yearStart: 2009, yearEnd: 2017),
        CarGenerationMeta(name: 'P87', yearStart: 2017, yearEnd: null),
      ]),
      CarModelMeta(name: '208', generations: [
        CarGenerationMeta(name: 'CA/CC', yearStart: 2012, yearEnd: 2019),
        CarGenerationMeta(name: 'UJ', yearStart: 2019, yearEnd: null),
      ]),
      CarModelMeta(name: 'Partner', generations: [
        CarGenerationMeta(name: 'M49', yearStart: 1996, yearEnd: 2008),
        CarGenerationMeta(name: 'B9', yearStart: 2008, yearEnd: 2019),
        CarGenerationMeta(name: 'K9', yearStart: 2019, yearEnd: null),
      ]),
    ],
  ),

  CarBrandMeta(
    name: 'Citroen',
    models: [
      CarModelMeta(name: 'C4', generations: [
        CarGenerationMeta(name: 'B51', yearStart: 2004, yearEnd: 2010),
        CarGenerationMeta(name: 'B71', yearStart: 2010, yearEnd: 2018),
        CarGenerationMeta(name: 'B81', yearStart: 2018, yearEnd: null),
      ]),
      CarModelMeta(name: 'C5', generations: [
        CarGenerationMeta(name: 'DC/DE', yearStart: 2001, yearEnd: 2007),
        CarGenerationMeta(name: 'TD/TE', yearStart: 2007, yearEnd: 2017),
      ]),
      CarModelMeta(name: 'C3', generations: [
        CarGenerationMeta(name: 'FC/FN', yearStart: 2002, yearEnd: 2009),
        CarGenerationMeta(name: 'SX', yearStart: 2009, yearEnd: 2016),
        CarGenerationMeta(name: 'SX facelift', yearStart: 2016, yearEnd: null),
      ]),
      CarModelMeta(name: 'Berlingo', generations: [
        CarGenerationMeta(name: 'M49', yearStart: 1996, yearEnd: 2008),
        CarGenerationMeta(name: 'B9', yearStart: 2008, yearEnd: 2018),
        CarGenerationMeta(name: 'K9', yearStart: 2018, yearEnd: null),
      ]),
    ],
  ),

  // ==================== АМЕРИКАНСКИЕ БРЕНДЫ ====================
  CarBrandMeta(
    name: 'Ford',
    models: [
      CarModelMeta(name: 'Focus', generations: [
        CarGenerationMeta(name: 'Mk1', yearStart: 1998, yearEnd: 2004),
        CarGenerationMeta(name: 'Mk2', yearStart: 2004, yearEnd: 2011),
        CarGenerationMeta(name: 'Mk3', yearStart: 2011, yearEnd: 2018),
        CarGenerationMeta(name: 'Mk4', yearStart: 2018, yearEnd: null),
      ]),
      CarModelMeta(name: 'Fusion/Mondeo', generations: [
        CarGenerationMeta(name: 'Mk3', yearStart: 2000, yearEnd: 2007),
        CarGenerationMeta(name: 'Mk4', yearStart: 2007, yearEnd: 2014),
        CarGenerationMeta(name: 'Mk5', yearStart: 2014, yearEnd: 2022),
      ]),
      CarModelMeta(name: 'Kuga/Escape', generations: [
        CarGenerationMeta(name: 'DM2', yearStart: 2008, yearEnd: 2012),
        CarGenerationMeta(name: 'DM3', yearStart: 2012, yearEnd: 2019),
        CarGenerationMeta(name: 'DM4', yearStart: 2019, yearEnd: null),
      ]),
      CarModelMeta(name: 'Explorer', generations: [
        CarGenerationMeta(name: 'U150-U251', yearStart: 1990, yearEnd: 2001),
        CarGenerationMeta(name: 'U251-U502', yearStart: 2001, yearEnd: 2010),
        CarGenerationMeta(name: 'U502', yearStart: 2010, yearEnd: 2019),
        CarGenerationMeta(name: 'U625', yearStart: 2019, yearEnd: null),
      ]),
      CarModelMeta(name: 'F-150', generations: [
        CarGenerationMeta(name: '11th gen', yearStart: 2004, yearEnd: 2008),
        CarGenerationMeta(name: '12th gen', yearStart: 2009, yearEnd: 2014),
        CarGenerationMeta(name: '13th gen', yearStart: 2015, yearEnd: 2020),
        CarGenerationMeta(name: '14th gen', yearStart: 2021, yearEnd: null),
      ]),
      CarModelMeta(name: 'Mustang', generations: [
        CarGenerationMeta(name: 'S197', yearStart: 2004, yearEnd: 2014),
        CarGenerationMeta(name: 'S550', yearStart: 2014, yearEnd: 2023),
        CarGenerationMeta(name: 'S650', yearStart: 2024, yearEnd: null),
      ]),
      CarModelMeta(name: 'Ranger', generations: [
        CarGenerationMeta(name: 'T6', yearStart: 2011, yearEnd: 2022),
        CarGenerationMeta(name: 'T6.2', yearStart: 2022, yearEnd: null),
      ]),
      CarModelMeta(name: 'Bronco', generations: [
        CarGenerationMeta(name: 'U130-U190', yearStart: 1966, yearEnd: 1996),
        CarGenerationMeta(name: 'U725', yearStart: 2021, yearEnd: null),
      ]),
    ],
  ),

  CarBrandMeta(
    name: 'Chevrolet',
    models: [
      CarModelMeta(name: 'Cruze', generations: [
        CarGenerationMeta(name: 'J300', yearStart: 2008, yearEnd: 2016),
        CarGenerationMeta(name: 'J400', yearStart: 2016, yearEnd: 2019),
      ]),
      CarModelMeta(name: 'Lacetti', generations: [CarGenerationMeta(name: 'J200', yearStart: 2002, yearEnd: 2013)]),
      CarModelMeta(name: 'Captiva', generations: [
        CarGenerationMeta(name: 'C100', yearStart: 2006, yearEnd: 2011),
        CarGenerationMeta(name: 'C140', yearStart: 2011, yearEnd: 2018),
        CarGenerationMeta(name: 'C140 FL', yearStart: 2018, yearEnd: null),
      ]),
      CarModelMeta(name: 'Tahoe', generations: [
        CarGenerationMeta(name: 'GMT800', yearStart: 2000, yearEnd: 2006),
        CarGenerationMeta(name: 'GMT900', yearStart: 2006, yearEnd: 2014),
        CarGenerationMeta(name: 'K2XX', yearStart: 2014, yearEnd: 2020),
        CarGenerationMeta(name: 'T1XX', yearStart: 2020, yearEnd: null),
      ]),
      CarModelMeta(name: 'Suburban', generations: [
        CarGenerationMeta(name: 'GMT800', yearStart: 2000, yearEnd: 2006),
        CarGenerationMeta(name: 'GMT900', yearStart: 2006, yearEnd: 2014),
        CarGenerationMeta(name: 'K2XX', yearStart: 2014, yearEnd: 2020),
        CarGenerationMeta(name: 'T1XX', yearStart: 2020, yearEnd: null),
      ]),
      CarModelMeta(name: 'Camaro', generations: [
        CarGenerationMeta(name: '5th gen', yearStart: 2009, yearEnd: 2015),
        CarGenerationMeta(name: '6th gen', yearStart: 2015, yearEnd: 2024),
      ]),
      CarModelMeta(name: 'Corvette', generations: [
        CarGenerationMeta(name: 'C6', yearStart: 2004, yearEnd: 2013),
        CarGenerationMeta(name: 'C7', yearStart: 2013, yearEnd: 2019),
        CarGenerationMeta(name: 'C8', yearStart: 2019, yearEnd: null),
      ]),
    ],
  ),

  CarBrandMeta(
    name: 'Jeep',
    models: [
      CarModelMeta(name: 'Grand Cherokee', generations: [
        CarGenerationMeta(name: 'ZJ', yearStart: 1993, yearEnd: 1998),
        CarGenerationMeta(name: 'WJ', yearStart: 1999, yearEnd: 2004),
        CarGenerationMeta(name: 'WK/WK2', yearStart: 2005, yearEnd: 2021),
        CarGenerationMeta(name: 'WL', yearStart: 2021, yearEnd: null),
      ]),
      CarModelMeta(name: 'Wrangler', generations: [
        CarGenerationMeta(name: 'YJ', yearStart: 1987, yearEnd: 1995),
        CarGenerationMeta(name: 'TJ', yearStart: 1997, yearEnd: 2006),
        CarGenerationMeta(name: 'JK', yearStart: 2007, yearEnd: 2018),
        CarGenerationMeta(name: 'JL', yearStart: 2018, yearEnd: null),
      ]),
      CarModelMeta(name: 'Cherokee', generations: [
        CarGenerationMeta(name: 'XJ', yearStart: 1984, yearEnd: 2001),
        CarGenerationMeta(name: 'KL', yearStart: 2013, yearEnd: 2023),
      ]),
      CarModelMeta(name: 'Compass', generations: [
        CarGenerationMeta(name: 'MK49', yearStart: 2007, yearEnd: 2017),
        CarGenerationMeta(name: 'MP', yearStart: 2017, yearEnd: null),
      ]),
    ],
  ),

  // ==================== ПРЕМИУМ И ДРУГИЕ ====================
  CarBrandMeta(
    name: 'Volvo',
    models: [
      CarModelMeta(name: 'XC60', generations: [
        CarGenerationMeta(name: '156', yearStart: 2008, yearEnd: 2017),
        CarGenerationMeta(name: '246', yearStart: 2017, yearEnd: null),
      ]),
      CarModelMeta(name: 'XC90', generations: [
        CarGenerationMeta(name: '275', yearStart: 2002, yearEnd: 2014),
        CarGenerationMeta(name: '256', yearStart: 2014, yearEnd: null),
      ]),
      CarModelMeta(name: 'S60', generations: [
        CarGenerationMeta(name: '252', yearStart: 2000, yearEnd: 2009),
        CarGenerationMeta(name: '134', yearStart: 2010, yearEnd: 2018),
        CarGenerationMeta(name: '224', yearStart: 2018, yearEnd: null),
      ]),
      CarModelMeta(name: 'V60', generations: [
        CarGenerationMeta(name: '155', yearStart: 2010, yearEnd: 2018),
        CarGenerationMeta(name: '236', yearStart: 2018, yearEnd: null),
      ]),
      CarModelMeta(name: 'S90/V90', generations: [
        CarGenerationMeta(name: '234/236', yearStart: 2016, yearEnd: null),
      ]),
      CarModelMeta(name: 'XC40', generations: [CarGenerationMeta(name: '536', yearStart: 2017, yearEnd: null)]),
    ],
  ),

  CarBrandMeta(
    name: 'Tesla',
    models: [
      CarModelMeta(name: 'Model S', generations: [CarGenerationMeta(name: 'Gen1/Gen2', yearStart: 2012, yearEnd: null)]),
      CarModelMeta(name: 'Model 3', generations: [CarGenerationMeta(name: 'Gen1', yearStart: 2017, yearEnd: null)]),
      CarModelMeta(name: 'Model X', generations: [CarGenerationMeta(name: 'Gen1/Gen2', yearStart: 2015, yearEnd: null)]),
      CarModelMeta(name: 'Model Y', generations: [CarGenerationMeta(name: 'Gen1', yearStart: 2020, yearEnd: null)]),
      CarModelMeta(name: 'Cybertruck', generations: [CarGenerationMeta(name: 'Gen1', yearStart: 2023, yearEnd: null)]),
    ],
  ),

  CarBrandMeta(
    name: 'Infiniti',
    models: [
      CarModelMeta(name: 'QX60', generations: [
        CarGenerationMeta(name: 'L50', yearStart: 2012, yearEnd: 2021),
        CarGenerationMeta(name: 'L51', yearStart: 2021, yearEnd: null),
      ]),
      CarModelMeta(name: 'QX80', generations: [CarGenerationMeta(name: 'Z62', yearStart: 2013, yearEnd: null)]),
      CarModelMeta(name: 'Q50', generations: [CarGenerationMeta(name: 'V37', yearStart: 2013, yearEnd: null)]),
      CarModelMeta(name: 'Q60', generations: [CarGenerationMeta(name: 'V37', yearStart: 2016, yearEnd: null)]),
    ],
  ),

  CarBrandMeta(
    name: 'Acura',
    models: [
      CarModelMeta(name: 'MDX', generations: [
        CarGenerationMeta(name: 'YD1', yearStart: 2000, yearEnd: 2006),
        CarGenerationMeta(name: 'YD2/YD3', yearStart: 2006, yearEnd: 2013),
        CarGenerationMeta(name: 'YD4', yearStart: 2013, yearEnd: 2020),
        CarGenerationMeta(name: 'YD5', yearStart: 2020, yearEnd: null),
      ]),
      CarModelMeta(name: 'RDX', generations: [
        CarGenerationMeta(name: 'TB1', yearStart: 2006, yearEnd: 2012),
        CarGenerationMeta(name: 'TB3/TB4', yearStart: 2012, yearEnd: 2018),
        CarGenerationMeta(name: 'TC1', yearStart: 2018, yearEnd: null),
      ]),
      CarModelMeta(name: 'TLX', generations: [
        CarGenerationMeta(name: 'UB', yearStart: 2014, yearEnd: 2020),
        CarGenerationMeta(name: 'UB2', yearStart: 2020, yearEnd: null),
      ]),
    ],
  ),

  CarBrandMeta(
    name: 'Suzuki',
    models: [
      CarModelMeta(name: 'Vitara', generations: [
        CarGenerationMeta(name: 'ET/EA', yearStart: 1988, yearEnd: 1998),
        CarGenerationMeta(name: 'LY', yearStart: 1998, yearEnd: 2014),
        CarGenerationMeta(name: 'LY facelift', yearStart: 2014, yearEnd: 2018),
        CarGenerationMeta(name: 'LY2', yearStart: 2018, yearEnd: null),
      ]),
      CarModelMeta(name: 'SX4', generations: [
        CarGenerationMeta(name: 'EY/GY', yearStart: 2006, yearEnd: 2014),
        CarGenerationMeta(name: 'JY', yearStart: 2014, yearEnd: null),
      ]),
      CarModelMeta(name: 'Jimny', generations: [
        CarGenerationMeta(name: 'JB23/JB43', yearStart: 1998, yearEnd: 2018),
        CarGenerationMeta(name: 'JB64/JB74', yearStart: 2018, yearEnd: null),
      ]),
      CarModelMeta(name: 'Swift', generations: [
        CarGenerationMeta(name: 'AZ/ZC', yearStart: 2004, yearEnd: 2010),
        CarGenerationMeta(name: 'FZ/NZ', yearStart: 2010, yearEnd: 2017),
        CarGenerationMeta(name: 'AZ', yearStart: 2017, yearEnd: null),
      ]),
    ],
  ),

  CarBrandMeta(
    name: 'Fiat',
    models: [
      CarModelMeta(name: 'Punto', generations: [
        CarGenerationMeta(name: '176', yearStart: 1993, yearEnd: 1999),
        CarGenerationMeta(name: '188', yearStart: 1999, yearEnd: 2012),
        CarGenerationMeta(name: '199', yearStart: 2012, yearEnd: 2018),
      ]),
      CarModelMeta(name: '500', generations: [CarGenerationMeta(name: '312', yearStart: 2007, yearEnd: null)]),
      CarModelMeta(name: 'Doblo', generations: [
        CarGenerationMeta(name: '119/223', yearStart: 2000, yearEnd: 2010),
        CarGenerationMeta(name: '263', yearStart: 2010, yearEnd: null),
      ]),
      CarModelMeta(name: 'Panda', generations: [
        CarGenerationMeta(name: '141', yearStart: 1980, yearEnd: 2003),
        CarGenerationMeta(name: '169', yearStart: 2003, yearEnd: 2012),
        CarGenerationMeta(name: '312', yearStart: 2012, yearEnd: null),
      ]),
    ],
  ),

  CarBrandMeta(
    name: 'Alfa Romeo',
    models: [
      CarModelMeta(name: 'Giulia', generations: [
        CarGenerationMeta(name: '105/115', yearStart: 1962, yearEnd: 1977),
        CarGenerationMeta(name: '952', yearStart: 2016, yearEnd: null),
      ]),
      CarModelMeta(name: 'Stelvio', generations: [CarGenerationMeta(name: '949', yearStart: 2016, yearEnd: null)]),
      CarModelMeta(name: 'Giulietta', generations: [CarGenerationMeta(name: '940', yearStart: 2010, yearEnd: 2020)]),
    ],
  ),

  CarBrandMeta(
    name: 'Jaguar',
    models: [
      CarModelMeta(name: 'F-Pace', generations: [CarGenerationMeta(name: 'X761', yearStart: 2016, yearEnd: null)]),
      CarModelMeta(name: 'E-Pace', generations: [CarGenerationMeta(name: 'X540', yearStart: 2017, yearEnd: null)]),
      CarModelMeta(name: 'XE', generations: [CarGenerationMeta(name: 'X760', yearStart: 2015, yearEnd: null)]),
      CarModelMeta(name: 'XF', generations: [
        CarGenerationMeta(name: 'X250', yearStart: 2007, yearEnd: 2015),
        CarGenerationMeta(name: 'X260', yearStart: 2015, yearEnd: null),
      ]),
      CarModelMeta(name: 'F-Type', generations: [CarGenerationMeta(name: 'X152', yearStart: 2013, yearEnd: null)]),
    ],
  ),

  CarBrandMeta(
    name: 'Land Rover',
    models: [
      CarModelMeta(name: 'Range Rover', generations: [
        CarGenerationMeta(name: 'L405', yearStart: 2012, yearEnd: 2021),
        CarGenerationMeta(name: 'L460', yearStart: 2021, yearEnd: null),
      ]),
      CarModelMeta(name: 'Range Rover Sport', generations: [
        CarGenerationMeta(name: 'L320', yearStart: 2005, yearEnd: 2013),
        CarGenerationMeta(name: 'L494', yearStart: 2013, yearEnd: 2022),
        CarGenerationMeta(name: 'L461', yearStart: 2022, yearEnd: null),
      ]),
      CarModelMeta(name: 'Discovery', generations: [
        CarGenerationMeta(name: 'L462', yearStart: 2016, yearEnd: null),
      ]),
      CarModelMeta(name: 'Defender', generations: [
        CarGenerationMeta(name: 'Series I-III', yearStart: 1948, yearEnd: 2016),
        CarGenerationMeta(name: 'L663', yearStart: 2019, yearEnd: null),
      ]),
      CarModelMeta(name: 'Evoque', generations: [
        CarGenerationMeta(name: 'L538', yearStart: 2011, yearEnd: 2018),
        CarGenerationMeta(name: 'L551', yearStart: 2018, yearEnd: null),
      ]),
      CarModelMeta(name: 'Velar', generations: [CarGenerationMeta(name: 'L560', yearStart: 2017, yearEnd: null)]),
    ],
  ),

  // ==================== КИТАЙСКИЕ БРЕНДЫ (популярные в РФ) ====================
  CarBrandMeta(
    name: 'Chery',
    models: [
      CarModelMeta(name: 'Tiggo 7', generations: [
        CarGenerationMeta(name: 'T15', yearStart: 2016, yearEnd: 2020),
        CarGenerationMeta(name: 'T15 FL', yearStart: 2020, yearEnd: null),
      ]),
      CarModelMeta(name: 'Tiggo 8', generations: [
        CarGenerationMeta(name: 'T19', yearStart: 2018, yearEnd: 2023),
        CarGenerationMeta(name: 'T19 FL', yearStart: 2023, yearEnd: null),
      ]),
      CarModelMeta(name: 'Arrizo 8', generations: [CarGenerationMeta(name: 'A8', yearStart: 2022, yearEnd: null)]),
    ],
  ),

  CarBrandMeta(
    name: 'Haval',
    models: [
      CarModelMeta(name: 'F7/F7x', generations: [CarGenerationMeta(name: 'GW4C20', yearStart: 2018, yearEnd: null)]),
      CarModelMeta(name: 'Jolion', generations: [CarGenerationMeta(name: 'H6', yearStart: 2020, yearEnd: null)]),
      CarModelMeta(name: 'Dargo', generations: [CarGenerationMeta(name: 'B01', yearStart: 2021, yearEnd: null)]),
      CarModelMeta(name: 'H9', generations: [CarGenerationMeta(name: 'H9', yearStart: 2015, yearEnd: null)]),
    ],
  ),

  CarBrandMeta(
    name: 'Geely',
    models: [
      CarModelMeta(name: 'Atlas/Atlas Pro', generations: [CarGenerationMeta(name: 'FY11', yearStart: 2018, yearEnd: null)]),
      CarModelMeta(name: 'Coolray', generations: [CarGenerationMeta(name: 'Binyue', yearStart: 2018, yearEnd: null)]),
      CarModelMeta(name: 'Monjaro', generations: [CarGenerationMeta(name: 'Xingyue L', yearStart: 2021, yearEnd: null)]),
      CarModelMeta(name: 'Tugella', generations: [CarGenerationMeta(name: 'FY11', yearStart: 2020, yearEnd: null)]),
    ],
  ),

  CarBrandMeta(
    name: 'Changan',
    models: [
      CarModelMeta(name: 'CS35 Plus', generations: [CarGenerationMeta(name: 'CS35P', yearStart: 2018, yearEnd: null)]),
      CarModelMeta(name: 'CS55', generations: [CarGenerationMeta(name: 'CS55', yearStart: 2017, yearEnd: null)]),
      CarModelMeta(name: 'CS75 Plus', generations: [CarGenerationMeta(name: 'CS75P', yearStart: 2019, yearEnd: null)]),
      CarModelMeta(name: 'UNI-K', generations: [CarGenerationMeta(name: 'UNI-K', yearStart: 2021, yearEnd: null)]),
    ],
  ),

  CarBrandMeta(
    name: 'FAW',
    models: [
      CarModelMeta(name: 'Bestune T77', generations: [CarGenerationMeta(name: 'T77', yearStart: 2018, yearEnd: null)]),
      CarModelMeta(name: 'Bestune T99', generations: [CarGenerationMeta(name: 'T99', yearStart: 2019, yearEnd: null)]),
    ],
  ),

  // ==================== ДОБАВЛЯЙТЕ НОВЫЕ БРЕНДЫ НИЖЕ ====================
  // CarBrandMeta(
  //   name: 'NewBrand',
  //   models: [
  //     CarModelMeta(
  //       name: 'ModelName',
  //       generations: [
  //         CarGenerationMeta(name: 'Gen1', yearStart: 2020, yearEnd: null),
  //       ],
  //     ),
  //   ],
  // ),
];