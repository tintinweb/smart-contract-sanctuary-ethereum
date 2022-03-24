/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.8.0;

contract Storage {
    uint256 number;

    function set(uint256 n) public {
        number = n;
    }

    function get() public view returns(uint256) {
        return number;
    }
}