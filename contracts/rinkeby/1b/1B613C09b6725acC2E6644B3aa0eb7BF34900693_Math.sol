/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

library Math {


    function percent(uint256 a, uint256 b) public pure returns(uint256){
        uint256 c = a - a*b/100;
        return c;
    }




}