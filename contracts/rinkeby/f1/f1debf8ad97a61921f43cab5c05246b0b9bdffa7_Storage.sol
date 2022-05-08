/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.8.0;

contract Storage {

    uint256 number;

    function store(uint256 num) public {
        number = num;
    }
    
    function retrieve() public view returns (uint256){
        return number;
    }
}