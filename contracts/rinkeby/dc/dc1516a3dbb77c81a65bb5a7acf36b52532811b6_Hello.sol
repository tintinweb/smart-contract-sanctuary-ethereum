/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

pragma solidity ^0.4.24;
contract Hello{
    string public name;
    constructor() public{
        name = "I am smart contract !";
    }
    function setName(string _name)public{
        name = _name;
    }
}