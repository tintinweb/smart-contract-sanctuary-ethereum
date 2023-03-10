/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

contract WinnerEvent {
    function callAttempt(address _winner) public {
        (bool success, ) = _winner.call("attempt()");
        require(success);
    }
}