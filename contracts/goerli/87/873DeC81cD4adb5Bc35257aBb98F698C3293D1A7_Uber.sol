// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Uber {
    struct Driver {
        bytes32 City;
        uint256 Ratings;
        bytes32 Name;
    }

    struct User {
        bytes32 Name;
        uint256 Strikes;
        bytes32 City;
        bool isPremium;
    }

    struct Ride {
        bool yesOrNo;
        bytes32 startLocation;
        bytes32 endLocation;
        address requester;
        uint256 timer;
    }

    uint256 Counter;
    mapping(address => Driver) public drivers;
    mapping(address => User) public users;
    mapping(address => address) public matchedUsersandDrivers;
    mapping(uint256 => Ride) public usersRequestingRide;

    modifier acceptedCity(string memory _city) {
        bool isCorrect = false;
        for (uint i = 0; i < acceeptedLocations.length; i++) {
            if (keccak256(abi.encodePacked(acceeptedLocations[i])) == keccak256(abi.encodePacked(_city))) {
                isCorrect = true;
            }
        }
        require(isCorrect, "City not accepted!");
        _;
    }

    string [] private acceeptedLocations;

    constructor(string [] memory _cities) {
        for (uint i = 0; i < _cities.length; i++) {
            acceeptedLocations.push(_cities[i]);
        }
    }

    function getAcceptedCities() public view returns (string [] memory) {
        return acceeptedLocations;
    }


    function RegisterDriver(address _addy, string memory _city, string memory _name) public acceptedCity(_city) {
        require(users[_addy].Name == bytes32(0x0000000000000000000000000000000000000000000000000000000000000000), "Already registered as a user!");
        require(drivers[_addy].Name == bytes32(0x0000000000000000000000000000000000000000000000000000000000000000), "Already registered!");
        bytes32 encodedCity = keccak256(abi.encode(_city));
        bytes32 encodedName = keccak256(abi.encode(_name));
        Driver memory driver = Driver(encodedCity, 0, encodedName);
        drivers[_addy] = driver;
    }

    function RegisterUser(address _addy, string memory _name, string memory _city, bool _premium) public acceptedCity(_city) {
        require(drivers[_addy].Name == bytes32(0x0000000000000000000000000000000000000000000000000000000000000000), "Already registered as a user!");
        require(users[_addy].Name == bytes32(0x0000000000000000000000000000000000000000000000000000000000000000), "Already registered!");
        bytes32 encodedName = keccak256(abi.encode(_name));
        bytes32 encodedCity = keccak256(abi.encode(_city));
        User memory user = User(encodedName, 0, encodedCity, _premium);
        users[_addy] = user;
    }

    function requestRide(string memory _location, string memory _destination) public {
        require(users[msg.sender].Name != 0, "You are not a registered User!");
        bytes32 encodedLocation = keccak256(abi.encode(_location));
        bytes32 encodedDestination = keccak256(abi.encode(_destination));
        Counter++;
        usersRequestingRide[Counter]= Ride(true, encodedLocation, encodedDestination, msg.sender, 0);
    }

    function acceptRide(uint256 _requestID) public {
        require(drivers[msg.sender].Name !=0, "You are not a registered Driver!");
        require(usersRequestingRide[_requestID].yesOrNo == true, "Invalid Request!");
        require(matchedUsersandDrivers[usersRequestingRide[_requestID].requester] == address(0), "Ride already accepted!");
        usersRequestingRide[_requestID].timer = block.timestamp;
        matchedUsersandDrivers[usersRequestingRide[_requestID].requester] = msg.sender; 
    }


    function cancel_ride(uint256 _requestID) public {
        require(matchedUsersandDrivers[msg.sender] != address(0), "There is no ride to cancel");
        uint256 starTime = usersRequestingRide[_requestID].timer;
        require(block.timestamp - starTime > 10000, "Insufficient time passed!");
        require(usersRequestingRide[_requestID].requester == msg.sender, "Not your ride to cancel!");
        matchedUsersandDrivers[msg.sender] = address(0);
    }

}