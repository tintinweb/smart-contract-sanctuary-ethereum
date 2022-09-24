// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BoxV2 {
    uint256 public length;
    uint256 public width;

    function init(uint256 _length, uint256 _width) public {
        length = _length;
        width = _width;
    }

    function area() public view returns (uint256) {
        return length * width;
    }

    function perimeter() public view returns (uint256) {
        return length * 2 + width * 2;
    }
}