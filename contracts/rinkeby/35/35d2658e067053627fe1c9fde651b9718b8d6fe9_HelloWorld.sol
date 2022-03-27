/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

pragma solidity ^0.4.24;
contract HelloWorld {
    string public name;
    
    constructor() public {
        name = "Hi! My name is Feather Chnug, I'm a blockchain engineer from Taiwan! : )";
    }
    
    function setName(string _name) public {
        name = _name;
    }
}