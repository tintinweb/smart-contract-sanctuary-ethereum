/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

pragma solidity ^0.4.24;
contract Hello {
    string public name;
    
    constructor() public {
        name = "我是一個智能合約範例！OH~YA!";
    }
    
    function setName(string _name) public {
        name = _name;
    }
}