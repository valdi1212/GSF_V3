USE 1212962259_FreshAir_International;

-- Stored Procedures

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

    DECLARE cvs_string TEXT;

    DECLARE done INT DEFAULT FALSE;

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

    SELECT originatingAirport
    FROM flightSchedules
    WHERE flightNumber = flight_number
    INTO flight_origin;

    SELECT destinationAirport
    FROM flightSchedules
    WHERE flightNumber = flight_number
    INTO flight_destination;

    SET cvs_string = concat(flight_number, '_', flight_origin, '-', flight_destination, '_', flight_date, ':\n\n');

    OPEN passengerListCursor;

    read_loop: LOOP
      FETCH passengerListCursor
      INTO person_id, person_name, seat_row, seat_num, seat_placement;

      SET cvs_string = concat(cvs_string, person_id, ';', person_name, ';', seat_row, seat_num, ';', seat_placement,
                              ';\n');

      IF done
      THEN
        LEAVE read_loop;
      END IF;
    END LOOP;
    CLOSE passengerListCursor;

    SELECT cvs_string;
  END $$
DELIMITER ;

-- CALL PassengerList('FA501', '2014-09-19');