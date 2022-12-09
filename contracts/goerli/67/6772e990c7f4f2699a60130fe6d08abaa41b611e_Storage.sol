/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    uint256 number;

    constructor()  {

    }

    function store(uint256 num) public payable {
        number = num;
    }

    function retrieve() public pure returns (uint256){
        return 1 + 1;
    }
}