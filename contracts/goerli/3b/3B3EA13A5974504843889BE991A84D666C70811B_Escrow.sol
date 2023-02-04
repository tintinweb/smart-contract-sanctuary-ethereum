/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Escrow {
    event Approved(uint);

    address public depositor;
    address public beneficiary;
    address public arbiter;
    bool public isApproved;
    uint public funding;

    constructor(address _arbiter, address _beneficiary) payable {
        arbiter = _arbiter;
        beneficiary = _beneficiary;
        depositor = msg.sender;
        funding = address(this).balance;
    }

    function approve() external {
        require(arbiter == msg.sender);
        (bool sent, ) = beneficiary.call{value: funding}("");
        require(sent);
        isApproved = true;
        emit Approved(funding);
    }
}