/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    event Call(address indexed caller, uint256 number);

    function callThis() external {
        emit Call(msg.sender, block.number);
    }

}