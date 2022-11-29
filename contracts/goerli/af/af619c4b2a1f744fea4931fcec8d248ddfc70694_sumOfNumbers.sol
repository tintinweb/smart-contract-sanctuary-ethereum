/**
 *Submitted for verification at Etherscan.io on 2022-11-29
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;

contract sumOfNumbers {

    uint256 x;
    uint256 y;

    function addNumbers(uint256 _x, uint256 _y) public {
        x = _x;
        y = _y;
    }

    function readNumbers() public view returns (uint256) {
        uint256 sum;
        sum = x + y;
        return sum;
    }

}