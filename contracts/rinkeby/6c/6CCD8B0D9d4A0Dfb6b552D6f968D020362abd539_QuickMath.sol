/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// File: TimeLock.sol

/*
 * @title: 
 * @author: Anthony (fps) https://github.com/fps8k .
 * @dev: 
*/

library QuickMath
{
    function add(uint256 a, uint256 b) external pure returns(bool, uint256)
    {
        if((a + b) > ((2 ** 256) - 1))
            return(false, 0);
        else
            return(true, a + b);
    }
}