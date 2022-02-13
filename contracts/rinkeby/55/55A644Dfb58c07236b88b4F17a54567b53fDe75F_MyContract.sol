/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;



// File: payable.sol

contract MyContract {

    mapping(address => uint) balances;

    function invest() external payable {
        if(msg.value < 1000){
            revert();
        }
        balances[msg.sender] += msg.value;
    }

    function balanceOf() external view returns (uint256) {
        return address(this).balance;
    }
}