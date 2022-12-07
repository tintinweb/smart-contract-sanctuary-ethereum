/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

pragma solidity ^0.4.24;
contract NCUE {
    string public name;
    
    constructor(string) public {
        name = "人生第一個智能合約！";
    }
    
    function setName(string _name) public {
        name = _name;
    }
}