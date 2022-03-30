/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



// File: MoodDiary.sol

contract HelloWorld {
    uint256 number;
    address public owner;
    event NumberChanged(uint256 newNumber);

    constructor() {
        owner = msg.sender;
    }

    function store(uint256 newNumber) public {
        number = newNumber;
        emit NumberChanged(newNumber);
    }

    function retrieve() public view returns(uint256) {
       return number;
    }

    function increment() public {
        number = number + 4;
        emit NumberChanged(number);

    }

}