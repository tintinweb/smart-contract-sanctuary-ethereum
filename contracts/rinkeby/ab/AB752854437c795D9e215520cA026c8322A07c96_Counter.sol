//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Counter {
    uint256 count;

    function getcount() public view returns (uint256) {
        return count;
    }

    function incrementcount() public {
        count++;
    }
}