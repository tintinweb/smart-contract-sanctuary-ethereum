/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

contract CompareNumbers{
    function compare(int16 a, int16 b, int16 c) public pure returns(bool){
        if(a > b && a > c){
            return true;
        } else if(a > c && a < b){
            return true;
        }else {
            return false;
        }
    }
}