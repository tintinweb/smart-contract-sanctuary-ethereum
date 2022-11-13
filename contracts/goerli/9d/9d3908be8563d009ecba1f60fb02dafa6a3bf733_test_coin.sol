/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract test_coin {
    address originalOwner;
    mapping(address => bool) public owner;
    string public symbol;

    constructor() public {
        originalOwner = msg.sender;
        owner[msg.sender] = true;
        symbol = "lin9";
    }

    function addOwner(address _newOwner) public isOwner{
        owner[_newOwner] = true;
    }

    function deleteOwner(address _toRemove) public isOwner{
        if(msg.sender == _toRemove){
            owner[_toRemove] = false;
        }
    }
    
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(owner[msg.sender], "Caller is not owner");
        _;
    }

    modifier isOriginalOwner() {
        require(msg.sender == originalOwner, "Caller is not the original owner");
        _;
    }
}