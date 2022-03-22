/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract StanHunter{

    address public owner;

    struct  Drop {
        string imageUri;
        string Name;
        string description;
        string social_1;
        string social_2;
        string websiteUri;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 sale;
        uint8 chain;
        bool approved;
    }

// "https://test.com/3.png",
// "Stan Colection",
// "New Drop",
// "twitter",
// "discord",
// "https://test.com/3.png",
// "3500",
// "12312312",
// "312321",
// "232213",
// 2,
// false

    Drop[] public drops;
    mapping (uint256 => address) public users;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner!");
        _;
    }
    //returnare lista dropuri
    function getDrops() public view returns(Drop[] memory){
        return drops;
    }

    //adaugare dropuri
    function addDrops(Drop memory _drop) public {
        _drop.approved = false;
        drops.push(_drop);
        uint256 id = drops.length - 1;
        users[id] = msg.sender; 
    } 

    function updateDrops(uint256 _index, Drop memory _drop) public {
        require(msg.sender == users[_index], "You are not the owner of this drop!");
        _drop.approved = false;
        drops[_index] = _drop;
    } 

    function approveDrop(uint256 _index) public onlyOwner{
        Drop storage drop = drops[_index];
        drop.approved = true;
    }

}