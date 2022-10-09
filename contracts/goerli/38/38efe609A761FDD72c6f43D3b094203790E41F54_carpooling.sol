// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract carpooling {
    // struct human {
    //     string name;
    //     uint8 age;
    //     string gender;
    // }
    struct ride {
        uint rideId;
        string origin;
        string destination;
        uint departuretime;
        uint fare;
        uint seats;
    }

    mapping (uint => address) public rideowner;
    mapping (uint => mapping(uint => address)) public rideToRider;

    uint8 ridecount = 0;
    ride[] public rides;
    // ride[] public searchRides;


    function createride(string memory _origin, string memory _destination, uint _departuretime, uint8 _seats, uint8 _fare) public {
        rides.push(ride(ridecount, _origin, _destination, _departuretime, _seats,_fare));
        rideowner[ridecount] = msg.sender;
        ridecount++;
    }  


    function searchride(string memory __origin, string memory __destination)public view returns(ride[] memory searchRides) {
        for (uint i = 0; i < ridecount; i = i+1) {
            ride storage checkRide;
            if (keccak256(abi.encodePacked(rides[i].origin)) == keccak256(abi.encodePacked(__origin)) && keccak256(abi.encodePacked(rides[i].destination)) == keccak256(abi.encodePacked(__destination)) && rides[i].seats > 0) { 
                checkRide = rides[i];
                searchRides[i] = checkRide;
            }
            
        }
        return searchRides;        
    }

    function bookRide(uint rideId) public {
        rideToRider[rideId][rides[rideId].seats] = msg.sender;
        rides[rideId].seats -= 1;
    }

}