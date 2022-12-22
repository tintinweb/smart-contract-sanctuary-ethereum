// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Contract1 {
    int private n;
    function setN(int n_) public {
        n = n_;
    }
    function getN() public view returns(int) {
        return n;
    }
}