/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

pragma solidity ^0.4.24;

contract Token {
     address public owner=0x2D631F41F6023Db409f15e1ccC337E69F62a8a58;
    uint public amount;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }

    function ()  payable public{
        amount += msg.value;
    }


    function withdraw() onlyOwner public {
        msg.sender.transfer(amount);
        amount = 0;
    }
}