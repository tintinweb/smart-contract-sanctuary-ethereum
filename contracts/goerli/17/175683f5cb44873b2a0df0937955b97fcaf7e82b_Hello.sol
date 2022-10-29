/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

pragma solidity ^0.4.24;

contract Hello {
    string public name;
    string public age;
    
    constructor() public {
        name = "我是一個智能合約！";
        age = "Wazzup";
    }
    
    function setName(string _name) public {
        name = _name;
    }
}