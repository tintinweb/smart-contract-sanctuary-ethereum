/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

pragma solidity ^0.4.24;
contract Hello {
    string public name;
    
    constructor() public {
        name = "I'm a smart contract deployed via MetaMask Account2 ！";
    }
    
    function setName(string _name) public {
        name = _name;
    }
}