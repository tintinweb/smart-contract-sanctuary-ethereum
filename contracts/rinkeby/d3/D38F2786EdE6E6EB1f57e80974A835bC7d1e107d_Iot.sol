/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;



error Iot__NotOwner();

contract Iot {


    struct stats {
        int256 temperature;
        int256 humidity;
        int256 moisture;
    }

    stats iotReading;

    constructor() {        
    }

    function updateIot(
        int256 _temperature,
        int256 _humidity,
        int256 _moisture
    ) public {
        iotReading = stats(_temperature, _humidity, _moisture);
    }

    function readStats() public view returns (stats memory) {
        return iotReading;
    }

   
}