/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

contract Sum {

    uint public count ;
    address public owner;

    constructor () {
        owner = msg.sender;
        count = 0;
    }

    modifier onlyOwner() {
        require(owner == msg.sender,"not the owner");
        _;
    }
    
    function set_owner(address _new_owner) public onlyOwner {
        owner = _new_owner;
    }

    function totalSum(uint x ,uint y) public {
        count = x + y ;
    }
}