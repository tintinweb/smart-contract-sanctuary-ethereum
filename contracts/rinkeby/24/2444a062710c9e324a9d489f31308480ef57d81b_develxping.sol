/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract develxping {
    
    address immutable i_owner;
    uint256 testNumber;

    constructor() {
        i_owner = msg.sender;
    }

    receive() external payable {}

    fallback() external payable {}

    function addNumber(uint256 _amount) public {
        testNumber = testNumber + _amount;
    }

    function publicFunction() public {
        testNumber = 0;
    }

    function privateFunction() internal {
        testNumber = 0;
    }

    function getNumber() public view returns (uint256) {
        return testNumber;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

}