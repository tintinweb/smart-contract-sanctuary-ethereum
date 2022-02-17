// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

import "./Cassette.sol";

contract CassetteFactory {

    // Readable version
    string constant public cassetteFactoryVersion = '0.0.1';

    Cassette[] public cassetteAddresses;
    Cassette public newestCassetteAddress;
    
    event CassetteCreated(Cassette cassette);

    function createCassette(uint256 timeLockSeconds) payable external {
        
        // Check there is an Asset value and an amount of time to work with first
        if(msg.value!=0 && timeLockSeconds!=0){
            Cassette cassette = new Cassette(timeLockSeconds);
            newestCassetteAddress = cassette;
            cassetteAddresses.push(cassette);
            emit CassetteCreated(cassette);
        }
    }
}