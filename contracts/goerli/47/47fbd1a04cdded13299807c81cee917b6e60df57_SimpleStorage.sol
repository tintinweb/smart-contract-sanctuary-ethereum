/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract SimpleStorage {
    uint256 stoerdData;

    function set(uint256 x) public {
        stoerdData = x;
    }

    function get() public view returns (uint256) {
        return stoerdData;
    }

    // Hello, World!
}