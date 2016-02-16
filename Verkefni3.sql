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
	
	declare passengerListCursor cursor
		for select personID, personName, rowNumber, seatNumber, seatPlacement
		from passengers join aircraftSeats on passengers.seatID = aircraftSeats.seatID;
		
	select originatingAirport 
	from flightSchedules
	where flightNumber = flight_number
	into flight_origin;
	
	select destinationAirport
	from flightSchedules
	where flightNumber = flight_number
	into flight_destination;
	
	set cvs_string = concat(flight_number, '_', flight_origin, '-', flight_destination, '_', flight_date, ':');
	
	select cvs_string;
end $$
delimiter ;

-- CALL PassengerList('FA501', '19-09-2014');