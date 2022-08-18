// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ExampleExternalContract { 
    bool public completed = false; 

    function complete() external payable { 
        completed = true;
    }

    function getBalance() public view returns(uint256) { 
        return address(this).balance;
    }
}