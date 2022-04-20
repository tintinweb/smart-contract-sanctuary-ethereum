/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

pragma solidity ^0.8.13;

contract Hello {
    string public name;

    constructor() public{
        name ="smart contract";
    }

    function setName(string memory  _name) public {
        name = _name;
    }

}