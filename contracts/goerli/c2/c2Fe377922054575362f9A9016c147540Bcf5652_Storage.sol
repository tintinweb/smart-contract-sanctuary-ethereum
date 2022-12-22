/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    uint256 number;

    constructor()  {

    }

    function store333(uint256 num) public payable {
        number = num;
    }

    function retrieve33311() public pure returns (uint256){
        return 1 + 4;
    }
}