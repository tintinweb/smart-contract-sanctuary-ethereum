/**
 *Submitted for verification at Etherscan.io on 2023-01-31
*/

pragma solidity ^0.4.18;
contract CallMeChallenge {
    bool public isComplete = false;
    function callme() public {
        isComplete = true;
    }
}