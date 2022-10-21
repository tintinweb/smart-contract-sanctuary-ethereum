// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

contract Contract {
    uint256[] public arr;

    function push(uint256 _num) public {
        arr.push(_num);
    }

    function pop() public {
        arr.pop();
    }
}