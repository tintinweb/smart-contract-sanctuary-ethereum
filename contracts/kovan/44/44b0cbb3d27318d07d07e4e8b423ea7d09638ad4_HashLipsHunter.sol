/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract HashLipsHunter{

    address public owner;

    // Define a NFT drop object based off of rarity.tools/upcoming
    struct Drop {
        string imageUri;
        string name;
        string description;
        string social_1;
        string social_2;
        string website;
        string price; //interesting we left this a string
        uint256 supply;
        uint256 presale;
        uint256 sale;
        uint8 chain; // 0..255 since we just need chain 0=ethereum, 1=polygon, etc.
        bool approved; // admins can set a flag to approve content prior to showing public
    }

// Test values for struct
//    "https://testtest.com/3.png",
//    "Test Colection",
//    "This is my drop for the month",
//    "twitter",
//    "https://testtest.com",
//    "fasfas",
 //   "0.03",
 //   "22",
 //   1635790237,
 //   1635790237,
 //   1,
//    false

    // Create a list of some sort to hold all the objects
    Drop[] public drops;
    mapping (uint256 => address) public users; // this maps

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(msg.sender == owner, "You are not the owner.");
        _;//this renders the code if the "require" statement is true
    }

    // Get the NFT drop objects list
    function getDrops() public view returns (Drop[] memory){
       return drops;
    }

    // Add to the NFT drop objects list
    function addDrop( Drop memory _drop ) public {
        _drop.approved = false;
        drops.push(_drop);  
        uint256 id = drops.length -1;
        users[id] = msg.sender; //assign a user and make sure only that user can update their structures
    }

    // Update the NFT drop objects listy
    function updateDrop(uint256 _index, Drop memory _drop ) public { 
        require (msg.sender == users[_index], "You are not the owner of this drop.");
        _drop.approved = false;
      drops[_index] = _drop;
    }

    // Remove from the NFT drop objects list
    // Approve an NFT drop object to enable displaying
    function approveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops [_index]; //storage means actually change the object.
        drop.approved = true;
    }
   

}