/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract NameContract {
    string private name;
    address public owner;

    constructor(string memory yourName) {              
        owner = msg.sender; 
        name = yourName;    
    }     

    function getName() external view returns (string memory) {
        return name;    
    }
}