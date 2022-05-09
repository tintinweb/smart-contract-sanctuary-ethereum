/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;

contract Storage {

    uint256 number;

    function store(uint256 _num) public {
        number = _num;
    }

    function retrieve() public view returns (uint256){
        return number;
    }
}