/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface Victim  {
    function setFee(uint256 _fee) external;
}

contract MaliciousContractMock {

    address private attack;

    event Paused(address account);
    event FlashLoan(address target, address initiator, address asset, uint256 amount, uint256 premium, uint16 referralCode);
    event OwnershipTransferred (address from, address to);

    constructor(){
        attack = 0x33305d57909B487b6DB733BeA40baE12A7C3A583;
    }


    function testPauseEvent() public {
        emit Paused(msg.sender);
    }

    function testFlashLoanAave() public {
        emit FlashLoan(address(0), address(0), address(0), 10, 10, 10);
    }

    function testOwnershipTransfer() public {
        emit OwnershipTransferred(msg.sender, address(1));
    }
}