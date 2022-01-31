/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// File: Test.sol

contract Test {
    uint256 public number = 1000;

    function getTicketNumber() public view returns (uint256) {
        return number;
    }

    function setTicketNumber(uint256 _ticketNumber) public {
        number = _ticketNumber;
    }
}