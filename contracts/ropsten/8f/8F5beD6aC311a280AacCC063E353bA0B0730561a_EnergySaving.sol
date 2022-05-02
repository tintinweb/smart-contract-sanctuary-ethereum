// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.8;

// import "../node_modules/hardhat/console.sol";
// import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title EnergySaving - a simple example contract.
 */
contract EnergySaving {
    string private greeting;

    constructor(string memory _greeting) {
        // console.log("Deploying a Greeter with greeting:", _greeting);
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        // console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
        greeting = _greeting;
    }

   /* event NewBusStop(uint busStopId, string stopName, string stopNameEn);

    struct BusStop {
        string stopId;
        string stopName;
        string stopNameEn;
        bool exists;
    }

    BusStop[] public busStops;

    function createBusStop(string memory _stopId, string memory _stopName, string memory _stopNameEn) public onlyOwner {
        
        //Operation push has changed behavior since since solidity 0.6. 
        //It no longer returns the length but a reference to the added element.
        
        busStops.push(BusStop(_stopId, _stopName, _stopNameEn, true));
        uint _id = busStops.length - 1;
        emit NewBusStop(_id, _stopName, _stopNameEn);
    }

    function removeBusStop(uint _id) public onlyOwner returns(BusStop[] memory) {
        require(busStops[_id].exists, "busStop does not exist.");
        delete busStops[_id];
        return busStops;
    }

    function getAllbusStop() view public returns(BusStop[] memory) {
        return busStops;
    }*/
}