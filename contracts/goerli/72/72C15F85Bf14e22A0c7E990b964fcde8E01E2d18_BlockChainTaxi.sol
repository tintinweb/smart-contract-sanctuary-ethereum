// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract BlockChainTaxi {
    string public route;

    event Ride(string rideRoute, uint ridePrice);

    constructor(string memory init_route) {
        route = init_route;
    }

    function getRoute() public view returns (string memory) {
        return route;
    }
    
    function setRoute(string memory _route) public {
        route = _route;
    }

    function RequestRide(string memory _route, uint ridePrice) public payable {
        // Uncomment this line, and the import of "hardhat/console.sol", to print a log in your terminal
        // console.log("Unlock time is %o and block timestamp is %o", unlockTime, block.timestamp);
        require(msg.value > ridePrice, "Not enough funds");

        route = _route;
        emit Ride(route, ridePrice);
    }
}