/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract HelloWorld{
    string public name;
    constructor(){
       name = "Hello, World!";
    }

    function set(string memory _name) public{
        name = _name;
    }
}