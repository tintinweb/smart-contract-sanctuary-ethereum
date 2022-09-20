/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract SimpleStorage {
    uint stroredData;

    function set(uint x) public {
        stroredData = x;
    }

    function get() public view returns (uint) {
        return stroredData;
    }
}