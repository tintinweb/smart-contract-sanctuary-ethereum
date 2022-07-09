/**
 *Submitted for verification at Etherscan.io on 2022-07-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract MyContract{
    uint8 x = 50;

    function getValue() public view returns(uint8){
        return x;
    }
}