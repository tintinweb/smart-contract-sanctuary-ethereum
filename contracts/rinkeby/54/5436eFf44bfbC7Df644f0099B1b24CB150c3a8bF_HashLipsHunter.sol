/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract HashLipsHunter {

    address public owner;
    // string name;

    struct Drop {
        string imageUri;
        string name;
        string description;
        string social_1;
        string social_2;
        string websiteUrl;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 sale;
        uint8 chain;
        bool approved;
    }
    Drop[] public drops;
    mapping (uint256 => address) public users;
    //string memory _name
    constructor(){
        // name = _name;
        owner = msg.sender;
    }
    
    modifier onlyOwner{
        require(msg.sender == owner, "You are not the owner: ");
        _;
    }

    function getDrops() public view returns (Drop[] memory){
        return drops;
    }

    function addDrop(Drop memory _drop) public {
        _drop.approved = false;
        drops.push(_drop);
        uint256 id = drops.length - 1;
        users[id] = msg.sender;
    }
    function updateDrop(
        uint256 _index,Drop memory _drop) public {
        require(msg.sender == users[_index], "you are not the owner of this drop: ");
        _drop.approved = false;
        drops[_index] = _drop;
    }
    function approveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;
    }
}
// "https://test.com/3.png",
// "Test collection",
// "This is my drop for the month",
// "twitter",
// "https//test.com",
// "fasfas",
// "0.01",
// "22",
// "1635447728",
// "1635447728",
// 1,
// false