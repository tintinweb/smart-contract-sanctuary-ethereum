/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

pragma solidity ^0.4.24;
contract Hello {
    string public name;
    
    constructor() public {
        name = "test yada 1234";
    }
    
    function setName(string _name) public {
        name = _name;
    }
}