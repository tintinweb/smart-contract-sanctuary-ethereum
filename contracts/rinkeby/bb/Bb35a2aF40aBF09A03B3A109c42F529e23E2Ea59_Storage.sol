// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

// create the contract
contract Storage
{
    // Declare a state variable
    uint256 number;

    // Define a function to store the number
    function store(uint256 num) public {
        number = num;
    }

    // define function to send back the stored number
    function retrieve() public view returns (uint256) {
        return number;
    }
}