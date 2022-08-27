/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

// File: SignUp.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SignUp {

    mapping(int256 => address) public userMap;
    
    int256 public counter = 2;

    event newUser(int256, address);

    constructor() {
        // Index of zero and one are reserved for burn account & xxx account  
        userMap[0] = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
        userMap[1] = 0x583031D1113aD414F02576BD6afaBfb302140225;
    }


    function addNewUser(address userAddr) public returns (int256) {
        userMap[counter++] = userAddr;
        
        emit newUser(counter, userAddr);

        return counter;
    }
}