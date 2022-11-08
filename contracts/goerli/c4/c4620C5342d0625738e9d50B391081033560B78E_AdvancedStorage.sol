// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract AdvancedStorage {
    uint256[] public ids;

    function add(uint256 _id) public {
        ids.push(_id);
    }

    function get(uint256 _index) public view returns (uint256) {
        return ids[_index];
    }

    function getAll() public view returns (uint256[] memory) {
        return ids;
    }

    function length() public view returns (uint256) {
        return ids.length;
    }
}