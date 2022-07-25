/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Payable {
    // Payable address can receive Ether
    address payable public owner;

    constructor() payable {
        owner = payable(msg.sender);
    }

    function transfer(address payable _to, uint _amount) public {
        // Note that "to" is declared as payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }
}