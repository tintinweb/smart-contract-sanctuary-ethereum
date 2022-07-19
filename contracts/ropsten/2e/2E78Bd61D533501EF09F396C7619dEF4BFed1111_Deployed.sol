// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract Deployed {

    uint256 total;

    function incr(uint256 num) public returns(bool) {
        total += num;
        return true;
    }

    function get() public view returns (uint256) {
        return total;
    }
}