/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Storage {

    address public contractAddress = address(this);
    bytes private BlockApex = hex"426c6f636b41706578";
    uint256 public Slot = 0;
    
    struct Passwords {
        string name;
        uint256 secretKey;
        string password;
    }
    Passwords[] private passwords;
    mapping (uint256 => Passwords) private destiny;

    function addValue(string memory _name , uint256 _secretKey, string memory _password) public {
        destiny[Slot].name = _name;
        destiny[Slot].secretKey = _secretKey;
        destiny[Slot].password = _password;
        Slot++;
    }
}