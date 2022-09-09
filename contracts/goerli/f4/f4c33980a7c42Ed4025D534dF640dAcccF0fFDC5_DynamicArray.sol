// SPDX-License-Identifier: NONE
// Author: @SoulChen;
pragma solidity ^0.8.9;

contract DynamicArray {
    uint[] public arr;
    address public owner;

    constructor() {
        owner = msg.sender;
        arr = [1, 2, 3, 4];
    }

    modifier OnlyOwner() {
        require(owner == msg.sender, "no permissios");
        _;
    }

    function remove(uint _index) public payable OnlyOwner {
        for (uint i = _index; i < arr.length - 1; i++) {
            arr[i] = arr[i + 1];
        }
        arr.pop();
    }

    function getArray() public view returns (uint[] memory) {
        return arr;
    }
}