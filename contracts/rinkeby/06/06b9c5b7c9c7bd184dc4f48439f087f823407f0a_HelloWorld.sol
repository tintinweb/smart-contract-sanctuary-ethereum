/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/*
 * @author itszona
 * @date 10/03/22
 */
contract HelloWorld {

    uint256 number;

    constructor(uint256 _param){
        number = _param;
    }

    function store(uint256 num) public {
        number = num;
    }

    function retrieve() public view returns (uint256){
        return number;
    }
}