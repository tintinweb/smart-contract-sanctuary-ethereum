/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyTest{
    event Recharge(address from, uint256 value);

    function recharge() external payable{        
        emit Recharge(msg.sender, msg.value);
    }
}