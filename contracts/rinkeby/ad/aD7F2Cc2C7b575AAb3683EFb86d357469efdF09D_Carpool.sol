/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Carpool {

    address private owner;
    Ride[] private rides;

    struct Ride {
        address payable driver;
        string start_place; // for now use city name as location
        string end_place; // for now use city name as location
        uint start_time; // at what time the ride is
        uint capacity; // how many people can join the ride;
        uint price; // price per person to join the ride
        address[] passengers; // passengers of this ride
        bool cancelled;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    modifier isDriver(uint ride_id) {
        require(ride_id >= 0 && ride_id < rides.length, "Ride does not exist");
        require(msg.sender == rides[ride_id].driver, "Caller is not driver");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function offerRide(string memory start_place, string memory end_place, uint start_time, uint capacity, uint price) public returns (uint){
        require(
            start_time > block.timestamp,
            "Cannot schedule a ride in the past"
        );
        require(
            capacity >= 1 && capacity <= 8,
            "The capacity should be between 1 and 8"
        );

        address[] memory emptyPassengerList;

        rides.push(Ride({
            driver: payable(msg.sender),
            start_place: start_place,
            end_place: end_place,
            start_time: start_time,
            capacity: capacity,
            price: price,
            passengers: emptyPassengerList,
            cancelled: false
        }));

        return rides.length -1; // subtract 1 since zero-indexed array
    }

    function cancelRide (uint ride_id) public isDriver(ride_id) {
        require(ride_id >= 0 && ride_id < rides.length, "Ride does not exist");
        rides[ride_id].cancelled = true;
    }

    function getPassengers(uint ride_id) public view isDriver(ride_id) returns (address[] memory) {
        require(ride_id >= 0 && ride_id < rides.length, "Ride does not exist");
        return rides[ride_id].passengers;
    }

    function getPossibleRide() public view
            returns (uint, Ride memory)
    {
        // todo take into account time, and start and end places
        // Ride[] memory possible_rides = new Ride[](20);
        // uint added_rides = 0;
        for (uint i = 0; i < rides.length; i++) {
            if (rides[i].cancelled == true){
                continue;
            }
            if (rides[i].passengers.length == rides[i].capacity){
                continue;
            }
            if(rides[i].start_time < block.timestamp){
                continue;
            }
            // possible_rides[added_rides] = rides[i];
            // added_rides++;
            // if(added_rides >= 20){
                // break;
            // }
            return (i, rides[i]);
        }
        revert("Could not find a ride");
    }

    function joinRide(uint ride_id) public payable{
        require(ride_id >= 0 && ride_id < rides.length, "Ride does not exist");
        require(
             msg.value >= rides[ride_id].price,
            "This ride is more expensive"
        );
        require(
            rides[ride_id].passengers.length < rides[ride_id].capacity,
            "Cannot join, this ride is already full"
        );
        require(
             rides[ride_id].start_time > block.timestamp,
            "Cannot join a ride in the past"
        );
        rides[ride_id].passengers.push(msg.sender);
        rides[ride_id].driver.transfer(msg.value);
    }





}