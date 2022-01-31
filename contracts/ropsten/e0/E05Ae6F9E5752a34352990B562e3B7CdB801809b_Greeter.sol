//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    function sub(uint256 _a, uint256 _i) public pure returns (uint256) {
        return _a / _i;
    }

    function qy(uint256 _a, uint256 _i) public pure returns (uint256) {
        return _a % _i;
    }
}