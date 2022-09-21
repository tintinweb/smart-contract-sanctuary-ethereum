/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0 < 0.9.0;

contract SimpleStorage {
    uint256 storedData;

    function set(uint256 _x) public {
        storedData = _x;
    }

    function get() public view returns(uint256){
        return storedData;
    }
}