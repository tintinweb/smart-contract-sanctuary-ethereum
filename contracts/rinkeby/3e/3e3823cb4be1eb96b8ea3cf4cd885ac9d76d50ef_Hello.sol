/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

pragma solidity ^0.5.0;
contract Hello {
    string public name;
    
    constructor() public {
        name = "我是一個智能合約！";
    }
    
    function setName(string memory _name) public {
        name = _name;
    }
}