/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract sobi{
    uint number;
    address owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function set(uint _number) public {
        number = _number;
    }

    function get() public onlyOwner view returns(uint NUMBER){
        NUMBER = number;
        return NUMBER;
    }
}