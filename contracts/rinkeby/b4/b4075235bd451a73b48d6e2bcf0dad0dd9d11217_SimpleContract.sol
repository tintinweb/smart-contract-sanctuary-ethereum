/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleContract {

    address public owner;
    uint public savedNumber;
    
    constructor(address _owner, uint _number) payable {
        owner = _owner;
        savedNumber = _number;
    }

    
    function updateNumber(uint _newNumber) public {
        savedNumber = _newNumber;
    }
    

    function getSavedNumber() public view returns (uint) {
        return savedNumber;
    }
}