// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract TrippieItemShop 
{
    event Purchase(address indexed purchaser, uint32 indexed itemId, uint weiValue);

    address public owner;

    constructor()     
    {        
        owner = msg.sender;
    }

    function buyItem(uint32 itemId) public payable
    {
        assert(msg.value > 0);
        emit Purchase(msg.sender, itemId, msg.value);
    } 

    function withdraw() public 
    {   
        assert(msg.sender == owner);
        (bool os, ) = payable(owner).call{value: address(this).balance}("");
        require(os);
    }
}