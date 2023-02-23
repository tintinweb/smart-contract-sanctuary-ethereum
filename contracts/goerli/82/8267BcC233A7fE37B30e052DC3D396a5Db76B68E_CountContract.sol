// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract CountContract {
    uint256 public count = 0;

    constructor (uint _count) {
        count = _count;
    }

    function getCount() public view returns (uint256) {
        return count;
    }

    function incrementCount() public {
        count += 1;
    }

    function decrementCount() public {
        count -= 1;
    }

    function setCount(uint256 _count) public {
        count = _count;
    }
}