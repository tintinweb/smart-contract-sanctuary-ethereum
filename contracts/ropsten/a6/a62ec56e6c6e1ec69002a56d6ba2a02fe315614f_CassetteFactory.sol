// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

import "./Cassette.sol";

contract CassetteFactory {

    // Readable version
    string constant public cassetteFactoryVersion = '0.0.1';

    // Factory records
    Cassette[] public cassetteAddresses;
    uint256 public cassettesCreated;
    
    // Factory events
    event CassetteCreated(Cassette cassette);

    // Create a new Cassette
    function createCassette(uint256 timeLockSeconds) payable external {
        
        // Check there is an Asset value and an amount of time to work with first
        if(msg.value!=0 && timeLockSeconds!=0){

            // Create a new Cassette
            //Cassette cassette = new Cassette(msg.sender, timeLockSeconds);

            // Create a new Cassette and endow with an Asset value
            Cassette cassette = (new Cassette){value: msg.value}(msg.sender, msg.value, timeLockSeconds);

            // Update the Cassette Factory records
            cassetteAddresses.push(cassette);
            cassettesCreated++;

            // Update the Cassette Factory events
            emit CassetteCreated(cassette);
        }
    }
}