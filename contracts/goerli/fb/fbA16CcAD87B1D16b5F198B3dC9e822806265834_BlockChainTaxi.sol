// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract BlockChainTaxi {
    uint public toLatitude;
    uint public toLongitude;
    uint public fromLatitude;
    uint public fromLongitude;
    uint public ridePrice;

    address passenger;
    address payable driver;

    bool isBusy = false; // whether the driver is available
    bool isResolved = true; // whether the contract is paid

    event Ride(uint fromLatitude, uint fromLongitude, uint toLatitude, uint toLongitude, uint ridePrice);

    function requestRide(uint _fromLatitude, uint _fromLongitude, uint _toLatitude, uint _toLongitude, uint _ridePrice) public payable {
        require(msg.value > ridePrice, "Not enough funds");
        require (isBusy == false, "Taxi is busy");
        require (isResolved == true, "Previous ride is not resolved");

        passenger = msg.sender;

        (bool success, ) = address(this).call{value: msg.value}("");
        require(success);

        fromLatitude = _fromLatitude;
        fromLongitude = _fromLongitude;
        toLatitude = _toLatitude;
        toLongitude = _toLongitude;
        ridePrice = _ridePrice;

        isBusy = true;
        isResolved = false;

        emit Ride(fromLatitude, fromLongitude, toLatitude, toLongitude, ridePrice);
    }

    function acceptTheRide() public {
        isBusy = true;
        driver = payable(msg.sender);
    }
      
    function resolveRideByUser() public {
        require(passenger == msg.sender, "Only passenger can resolve it");        
        isBusy = false;
        isResolved = true;
    }

    function getPaidByDriver() public payable {
        require(isResolved);
        require(driver == msg.sender, "Only driver can request the payment");
        uint toPaySum = ridePrice * 9 / 10; // we take 10% cut
        (bool success, ) = payable(msg.sender).call{value: toPaySum}("");
        require(success);
    }
}

    /*
    function resolveRideByDriver(uint _currentLatitude, uint _currentLongitude) public {
        require(driver == payable(msg.sender), "Only driver can resolve it");
        
        uint longDist = abs(int(_currentLongitude - toLongitude));
        uint latDist = abs(int(_currentLatitude - toLatitude));

        require (longDist < )
        
        isBusy = false;
        isResolved = true;

    }

    function abs(int x) private pure returns (uint) {
        return uint(x >= 0 ? x : -x);
    }*/