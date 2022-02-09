/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract NFTcreepto {

        address public owner;
        struct Drop {
        string imageUrl;
        string name;
        string descreption;
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

// "https://testtest.com/3.png",
// "Test connection",
// "this is my first code",
// "twitter",
// "https://testtest.com",
// "fasfas",
// "0.001",
// "22",
// 1635790237,
// 1635790237,
// 1,
// false

    Drop[] public drops;
    mapping (uint256 => address) public users;

    constructor(){
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner, "You are not he owner");
        _;
    }

    //get
    function getDrops() public view returns (Drop[] memory){
        return drops;
    }

    //add
    function addDrop(Drop memory _drop) public {
        _drop.approved = false;
        drops.push(_drop);
         uint256 id = drops.length - 1;
         users[id] = msg.sender;  

    }

        function updateDrop(
        uint256 _index, Drop memory _drop) public {
        require(msg.sender == users[_index], "You are not of this dorp");
        _drop.approved = false;
        
        drops[_index] = _drop;

    }
    //Remove

    //Approve
    function approveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;

    }
}