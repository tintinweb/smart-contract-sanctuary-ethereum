/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Attacker {
    function whoAmi() public view returns (address) {
        return msg.sender;
    }
}