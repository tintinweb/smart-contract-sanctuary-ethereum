/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//Holds the location on a snail and the address of the owner
//Whenever the ownership changes the snails location is increased by 1
//If the snail reaches a certain location it will be considered a winner
contract SnailContract {
    //Each Snail has a set of qualities
    /* 
    * Location, an int that holds the position the snail is at in the race(similar to how many meters it has moved since the start)
    * Owner, the address of the current owner of the snail
    * possibleOwners, a array of size a size which holds the two possible addresses that can become owners of the snail
    */
    struct Snail {
        uint location;
        address owner;
        address[2] possibleOwners;
    }
    
    //Array of Snails that are in play
    Snail[] public snails;
    //Constructor that creates the game according to the specified snail count
    constructor(uint _snailCount, address[] memory _playerAddresses) {
        require(_snailCount > 0, "Snail count must be greater than 0");
        require(_playerAddresses.length % 2 == 0, "Player count needs to be even");
        require(_playerAddresses.length != 0, "Player count needs to greater than 0");
        //Create a Snail
        uint addrPointer = 0;
        for (uint i = 0; i < _snailCount; i++) {
            Snail memory snail = Snail(0, _playerAddresses[addrPointer], [_playerAddresses[addrPointer],_playerAddresses[addrPointer+1]]);
            snails.push(snail);
            addrPointer += 2;
        }
    }
    function getSnail(uint _snailId) public view returns (uint, address,address,address) {
        Snail memory snail = snails[_snailId];
        return (snail.location, snail.owner, snail.possibleOwners[0], snail.possibleOwners[1]);
    }
    function transferSnail(uint _snailId) public {
        Snail storage snail = snails[_snailId];
        require(snail.owner != msg.sender, "You currently own this snail");
        require((snail.possibleOwners[0] == msg.sender || snail.possibleOwners[1] == msg.sender), "You need to be a possible owner this snail");
        require(!isWinner(_snailId), "This snail has already won");
        snail.owner = msg.sender;
        snail.location++;
    }
    function isWinner(uint _snailId) public view returns (bool) {
        Snail memory snail = snails[_snailId];
        return snail.location >= 10;
    }
    //Add time stuff

}