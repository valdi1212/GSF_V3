USE 1212962259_FreshAir_International;

-- Stored Procedures

delimiter $$
drop procedure if exists PassengerList $$
create procedure PassengerList(flight_number CHAR(5), flight_date DATE)
begin

	declare flight_origin char(3);
	declare flight_destination char(3);

	declare cvs_string text;
	
	declare done int default false;
	
	declare passengerListCursor cursor for 
		select personID, personName, rowNumber, seatNumber, seatPlacement
		from passengers 
		join aircraftSeats on passengers.seatID = aircraftSeats.seatID
		join aircrafts on aircraftSeats.aircraftID = aircrafts.aircraftID
		join flights on aircrafts.aircraftID = flights.aircraftID
		where flight_Number = flights.flightNumber AND flight_date = flights.flightDate;
	
	declare continue handler for not found set done = true;
		
	select originatingAirport 
	from flightSchedules
	where flightNumber = flight_number
	into flight_origin;
	
	select destinationAirport
	from flightSchedules
	where flightNumber = flight_number
	into flight_destination;
	
	set cvs_string = concat(flight_number, '_', flight_origin, '-', flight_destination, '_', flight_date, ':\n\n');
	
	open passengerListCursor;
	
	read_loop: loop
		fetch passengerListCursor
		into -- declare the variables at the top...
	
	--select cvs_string;
end $$
delimiter ;

-- CALL PassengerList('FA501', '2014-09-19');