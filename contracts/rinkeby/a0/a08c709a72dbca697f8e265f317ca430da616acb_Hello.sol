/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

pragma solidity ^0.4.24;
contract Hello{
    string public name;

    constructor() public {
        name = "test";
    }
    function setName(string _name) public{
        name = _name;
    }
}