/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

contract Deposit {
    receive() external payable {

    }
    fallback() external payable {

    }
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
}