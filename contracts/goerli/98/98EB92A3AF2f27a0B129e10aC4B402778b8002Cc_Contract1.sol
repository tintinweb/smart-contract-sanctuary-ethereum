// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract Contract1 {
    uint256 someNumber;

    function viewNumber() public view returns (uint256) {
        return someNumber;
    }

    function updateNumber(uint256 _someNumber) public {
        someNumber = someNumber + _someNumber;
    }
}