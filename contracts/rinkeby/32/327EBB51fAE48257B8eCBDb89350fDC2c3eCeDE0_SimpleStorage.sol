/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract SimpleStorage {
    uint256 [] storedData;

    constructor() {
        storedData.push(0);
    }

    function set(uint x) public {
        storedData.push(x);
    }

    function get(uint256 _index) public view returns (uint256) {
        return storedData[_index];
    }

    function size() public view returns (uint256) {
        return storedData.length;
    }
}