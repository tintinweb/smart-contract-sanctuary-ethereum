/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

contract Math {

    uint total;

    function add(uint a, uint b) public {
        total = a + b;
    }

    function getTotal() public view returns (uint) {
        return total;
    }
}