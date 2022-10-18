/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Storage {

    uint256 number;


    function store(uint256 num, uint256 num2, uint256 num3) public {
        number = num * 100 + num2 * 10 + num3;
    }


    function retrieve() public view returns (uint256){
        return number;
    }
}