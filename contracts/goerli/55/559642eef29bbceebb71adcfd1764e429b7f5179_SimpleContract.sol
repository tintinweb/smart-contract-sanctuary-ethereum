/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// Root file: test/contracts/SimpleContract.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract SimpleContract {
    string public constant hello = "world";
    uint256 public number;

    constructor(uint256 _number) {
        number = _number;
    }

    function viewSender() view public returns(address) {
        return msg.sender;
    }
}