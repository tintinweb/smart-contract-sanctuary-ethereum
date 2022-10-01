/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract MyContract {
    mapping(string => uint) inheritance; 

    function addHeir(string memory _name, uint _value) public {
        inheritance[_name] = _value; 
    }

    function recoverInheritance(string memory _name) public view returns(uint) {
        return inheritance[_name]; 
    }
    
}