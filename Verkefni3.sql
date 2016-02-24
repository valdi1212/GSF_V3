USE 1212962259_FreshAir_International;

-- Functions


-- Function to find the revenue of a specified month and flight route - part of the solution for #4
DELIMITER $$
DROP FUNCTION IF EXISTS RouteRevenueByMonth $$
CREATE FUNCTION RouteRevenueByMonth(spec_year INT, spec_month INT, origin_airport CHAR(3), dest_airport CHAR(3))
  RETURNS INT
  BEGIN
    RETURN (SELECT sum(profits(flightCode))
            FROM flightschedules
              JOIN flights ON flightschedules.flightNumber = flights.flightNumber
            WHERE
              year(flightDate) = spec_year AND month(flightDate) = spec_month AND originatingAirport = origin_airport
              AND
              destinationAirport = dest_airport);
  END $$
DELIMITER ;


-- Stored Procedures
/*1: Skrifið   Stored   Procedure, PassengerList()
sem   notar   Cursor   til   að   setja   saman   farþegaskrá   á textaformi(CSV) fyrir ákveðið flug.
Flugnúmer(flightNumber) og flugdagur(flightDate) ákvarða hvaða flug er valið.*/

DELIMITER $$
DROP PROCEDURE IF EXISTS PassengerList $$
CREATE PROCEDURE PassengerList(flight_number CHAR(5), flight_date DATE)
  BEGIN

    -- variables for the header
    DECLARE flight_origin CHAR(3);
    DECLARE flight_destination CHAR(3);

    -- variables for the cursor
    DECLARE person_id VARCHAR(35);
    DECLARE person_name VARCHAR(75);
    DECLARE seat_row TINYINT(4);
    DECLARE seat_num CHAR(1);
    DECLARE seat_placement VARCHAR(15);
    DECLARE plane_type VARCHAR(35);

    DECLARE cvs_string TEXT;

    DECLARE done INT DEFAULT FALSE;

    -- declaring the cursor
    DECLARE passengerListCursor CURSOR FOR
      SELECT
        personID,
        personName,
        rowNumber,
        seatNumber,
        seatPlacement
      FROM passengers
        JOIN aircraftSeats ON passengers.seatID = aircraftSeats.seatID
        JOIN aircrafts ON aircraftSeats.aircraftID = aircrafts.aircraftID
        JOIN flights ON aircrafts.aircraftID = flights.aircraftID
      WHERE flight_Number = flights.flightNumber AND flight_date = flights.flightDate;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- selecting data into their respective variables
    SELECT originatingAirport
    FROM flightSchedules
    WHERE flightNumber = flight_number
    INTO flight_origin;

    SELECT destinationAirport
    FROM flightSchedules
    WHERE flightNumber = flight_number
    INTO flight_destination;

    SELECT aircraftType
    FROM aircrafts
      JOIN flights ON aircrafts.aircraftID = flights.aircraftID
    WHERE flightNumber = flight_number AND flightDate = flight_date
    INTO plane_type;

    -- adding the header to the string
    SET cvs_string = concat(flight_number, '_', flight_origin, '-', flight_destination, '_', flight_date, ':\n\n');

    -- adding the body to the string using the cursor
    OPEN passengerListCursor;

    read_loop: LOOP
      FETCH passengerListCursor
      INTO person_id, person_name, seat_row, seat_num, seat_placement;

      -- checks if the loop has run its course
      IF done
      THEN
        LEAVE read_loop;
      END IF;

      -- concats the necessary variables into the string
      SET cvs_string = concat(cvs_string, person_id, ';', person_name, ';', seat_row, seat_num, ';', seat_placement,
                              ';\n');
    END LOOP;
    CLOSE passengerListCursor;

    -- adding the footer to the string
    SET cvs_string = concat(cvs_string, '\nCARRIER: ', plane_type, '\nList Compiled ',
                            cast(curdate() AS CHAR));

    -- shows the string, or at least a part of it. depends on platform.
    SELECT cvs_string;
  END $$
DELIMITER ;

/*3:Skrifið Stored Procedure AircraftSchedule() sem notar Pivot til að birta upplýsingar á töfluformi um
hvaða flugvélar fljúga hvaða flug og á hvaða vikudegi. Færibreyturnar
eru vélarnúmer(aircraftID) og brottfararstaður(originatingAirport)*/

DELIMITER $$
DROP PROCEDURE IF EXISTS AircraftSchedule $$
CREATE PROCEDURE AircraftSchedule(aircraft_id CHAR(11), origin_airport CHAR(3))
  BEGIN
    SELECT
      flightDate,
      CASE dayname(flightDate)
      WHEN 'Monday'
        THEN flights.flightNumber
      ELSE '' END AS 'Monday',
      CASE dayname(flightDate)
      WHEN 'Tuesday'
        THEN flights.flightNumber
      ELSE '' END AS 'Tuesday',
      CASE dayname(flightDate)
      WHEN 'Wednesday'
        THEN flights.flightNumber
      ELSE '' END AS 'Wednesday',
      CASE dayname(flightDate)
      WHEN 'Thursday'
        THEN flights.flightNumber
      ELSE '' END AS 'Thursday',
      CASE dayname(flightDate)
      WHEN 'Friday'
        THEN flights.flightNumber
      ELSE '' END AS 'Friday',
      CASE dayname(flightDate)
      WHEN 'Saturday'
        THEN flights.flightNumber
      ELSE '' END AS 'Saturday',
      CASE dayname(flightDate)
      WHEN 'Sunday'
        THEN flights.flightNumber
      ELSE '' END AS 'Sunday'
    FROM flightschedules
      JOIN flights ON flightschedules.flightNumber = flights.flightNumber
      JOIN aircrafts ON flights.aircraftID = aircrafts.aircraftID
    WHERE aircrafts.aircraftID = aircraft_id
          AND originatingAirport = origin_airport
    GROUP BY flightDate;
  END $$
DELIMITER ;

/*4: Skrifið Stored Procedure ScheduleRevenue()
sem notar Pivot til að birta upplýsingar á töfluformi um hvaða tekjur FreshAir hefur
af ákveðnum flugleiðum yfir fjórðung úr ári(1 = fyrsti fjórðungur, 2 = annar,3 = þriðji og 4= fjórði).
Parametrarnir eru ártalið og númer ársfjórðungs.*/

DELIMITER $$
DROP PROCEDURE IF EXISTS ScheduleRevenue $$
CREATE PROCEDURE ScheduleRevenue(spec_year INT, year_quarter TINYINT)
  BEGIN

    -- Uses case for each quarter, to determine month name. Can't figure out how to change name(AS) on an instance basis. Annoyingly repetitive.
    CASE year_quarter
      WHEN 1
      THEN (SELECT
              concat(originatingAirport, '-', destinationAirport)                                                  AS 'Flight route',
              RouteRevenueByMonth(spec_year, 1 + ((year_quarter - 1) * 3), originatingAirport,
                                  destinationAirport)                                                              AS 'jan',
              RouteRevenueByMonth(spec_year, 2 + ((year_quarter - 1) * 3), originatingAirport,
                                  destinationAirport)                                                              AS 'feb',
              RouteRevenueByMonth(spec_year, 3 + ((year_quarter - 1) * 3), originatingAirport,
                                  destinationAirport)                                                              AS 'mar'
            FROM flightschedules
              JOIN flights ON flightschedules.flightNumber = flights.flightNumber
            WHERE year(flightDate) = spec_year
            GROUP BY originatingAirport, destinationAirport);
      WHEN 2
      THEN (SELECT
              concat(originatingAirport, '-', destinationAirport)                                                  AS 'Flight route',
              RouteRevenueByMonth(spec_year, 1 + ((year_quarter - 1) * 3), originatingAirport,
                                  destinationAirport)                                                              AS 'apr',
              RouteRevenueByMonth(spec_year, 2 + ((year_quarter - 1) * 3), originatingAirport,
                                  destinationAirport)                                                              AS 'may',
              RouteRevenueByMonth(spec_year, 3 + ((year_quarter - 1) * 3), originatingAirport,
                                  destinationAirport)                                                              AS 'jun'
            FROM flightschedules
              JOIN flights ON flightschedules.flightNumber = flights.flightNumber
            WHERE year(flightDate) = spec_year
            GROUP BY originatingAirport, destinationAirport);
      WHEN 3
      THEN (SELECT
              concat(originatingAirport, '-', destinationAirport)                                                  AS 'Flight route',
              RouteRevenueByMonth(spec_year, 1 + ((year_quarter - 1) * 3), originatingAirport,
                                  destinationAirport)                                                              AS 'jul',
              RouteRevenueByMonth(spec_year, 2 + ((year_quarter - 1) * 3), originatingAirport,
                                  destinationAirport)                                                              AS 'aug',
              RouteRevenueByMonth(spec_year, 3 + ((year_quarter - 1) * 3), originatingAirport,
                                  destinationAirport)                                                              AS 'sep'
            FROM flightschedules
              JOIN flights ON flightschedules.flightNumber = flights.flightNumber
            WHERE year(flightDate) = spec_year
            GROUP BY originatingAirport, destinationAirport);
      WHEN 4
      THEN (SELECT
              concat(originatingAirport, '-', destinationAirport)                                                  AS 'Flight route',
              RouteRevenueByMonth(spec_year, 1 + ((year_quarter - 1) * 3), originatingAirport,
                                  destinationAirport)                                                              AS 'oct',
              RouteRevenueByMonth(spec_year, 2 + ((year_quarter - 1) * 3), originatingAirport,
                                  destinationAirport)                                                              AS 'nov',
              RouteRevenueByMonth(spec_year, 3 + ((year_quarter - 1) * 3), originatingAirport,
                                  destinationAirport)                                                              AS 'dec'
            FROM flightschedules
              JOIN flights ON flightschedules.flightNumber = flights.flightNumber
            WHERE year(flightDate) = spec_year
            GROUP BY originatingAirport, destinationAirport);
    END CASE;
  END $$
DELIMITER ;


-- Views


-- skilar: Verði,heiti verðflokks,lágmarksverði,endurgreiðanleika,gildandi farrými.
DELIMITER $$
DROP VIEW IF EXISTS ValidPriceOffers $$
CREATE VIEW ValidPriceOffers AS
  SELECT
    prices.amount,
    priceCategories.categoryName,
    priceCategories.minimumPrice,
    priceCategories.refundable
  -- gildandi farrými?
  FROM prices
    JOIN pricecategories ON prices.priceCategoryID = pricecategories.categoryID
  ORDER BY prices.amount DESC;
DELIMITER ;

-- skilar:  Flugnúmeri,flugleið,millilendingarstað,áætluðum biðtíma.
DELIMITER $$
DROP VIEW IF EXISTS StopoverDestinations $$
CREATE VIEW StopoverDestinations AS
  SELECT
    flightschedules.flightNumber,
    flightschedules.originatingAirport,
    -- gerði ráð fyrir að flugleið meinar byrjunar- og endastað
    flightschedules.destinationAirport,
    stopovers.IATAcode,
    stopovers.stopTime
  FROM flightschedules
    JOIN stopovers ON flightschedules.flightNumber = stopovers.flightNumber;
DELIMITER ;

-- skilar:  Auðkenni flugvélar,sætisauðkenni,sætisröð,sætisnúmeri.
DELIMITER $$
DROP VIEW IF EXISTS AircraftFirstClassSeats $$
CREATE VIEW AircraftFirstClassSeats AS
  SELECT
    aircraftID,
    seatID,
    rowNumber,
    seatNumber
  FROM aircraftseats
  WHERE classID = 1;
DELIMITER ;

-- skilar: Flugvallarkóða,flugvallarheiti,borg,landi,landskóða(alpha 336612)
DELIMITER $$
DROP VIEW IF EXISTS AirportInfo $$
CREATE VIEW AirportInfo AS
  SELECT
    IATAcode,
    airportName,
    cityName,
    countryName,
    alpha336612
  FROM airports
    JOIN cities ON airports.cityID = cities.cityID
    JOIN countries ON cities.countryCode = countries.alpha336612;
DELIMITER ;


-- TESTS
/*
CALL PassengerList('FA501', '2014-05-01');
SELECT * FROM ValidPriceOffers;
SELECT * FROM StopoverDestinations;
SELECT * FROM AircraftFirsClassSeats;
SELECT * FROM AirportInfo;
CALL AircraftSchedule('TF-CNA', 'KEF');
SELECT RouteRevenueByMonth(2014, 5, 'KEF', 'OSL');
CALL ScheduleRevenue(2014, 2);
*/