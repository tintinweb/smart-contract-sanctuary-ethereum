/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11; 


contract Hero {
    address owner;
    string hero;
    constructor(string memory _hero){
        owner = msg.sender;
        hero = _hero;
    }

    function setHero(string memory _hero)public
    {
        require(msg.sender==owner,"Not the owner");
        hero = _hero;
    }
    function getHero() public view returns(string memory)
    {
        return hero;
    }
}