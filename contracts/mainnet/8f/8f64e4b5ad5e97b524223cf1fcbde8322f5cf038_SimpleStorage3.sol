// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

//    ____  _  _      ____  _     _____
//  / ___\/ \/ \__/|/  __\/ \   /  __/
//  |    \| || |\/|||  \/|| |   |  \  
//  \___ || || |  |||  __/| |_/\|  /_ 
//  \____/\_/\_/  \|\_/   \____/\____\
contract SimpleStorage3 {
    //
    event NumberSet(address indexed setter, uint8 newNumber);

    uint8 private number = 1;

    function set(uint8 _number) external {
        number = _number;
        emit NumberSet(msg.sender, number);
    }

    function get() external view returns (uint8) {
        return number;
    }
}