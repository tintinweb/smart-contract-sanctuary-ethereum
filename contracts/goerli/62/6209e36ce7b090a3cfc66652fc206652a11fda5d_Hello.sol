/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

pragma solidity ^0.4.24;
contract Hello {
    string public name;
    
    constructor() public {
        name = "智能合約！";
    }
    
    function setName(string _name) public {
        name = _name;
    }
}