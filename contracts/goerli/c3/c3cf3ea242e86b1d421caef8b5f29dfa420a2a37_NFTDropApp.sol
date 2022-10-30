/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract NFTDropApp {
    address public owner;

    // Define a NFT drop object
    struct Drop {
        string imageUri;
        string  name;
        string  description;
        string  social_1;  
        string  social_2;
        string  websiteUri;
        string  price;
        uint    supply;
        uint    presale;  
        uint    sale;  
        uint8   chain;
        bool approved;  
    }
    // Create a list of some sort to hold all the objects
    Drop[] public dropList;
    mapping (uint => address) public users;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner.");
        _;
    }

    // Get the NFT drop object list
    function getDrops() public view returns(Drop[] memory) {
        return dropList;
    }
    // Add to the NFT drop objects list
    function addDrop(Drop memory _drop) public {
        _drop.approved = false;
        dropList.push(_drop);
        uint id = dropList.length - 1;
        users[id] = msg.sender;
    }
    // UPDATE to the NFT drop objects list
    function updateDrop( uint _index, Drop memory _drop) public {
        require(msg.sender == users[_index], "You are not the owner of this drop.");
        _drop.approved = false;
        dropList[_index] = _drop;
    }
    //
    // Approve an NFT drop object to enable displaying
    function approveDrop(uint _index) public onlyOwner{
        Drop storage drop = dropList[_index];
        drop.approved = true;
    }
}