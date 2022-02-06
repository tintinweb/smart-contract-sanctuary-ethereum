/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Nfthunter {

    address public owner;
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner");
        _;

    }
    // Defining a NFT Drop Object

    struct Drop {
        string imageUri;
        string name;
        string description;
        string social1;
        string social2;
        string websiteUri;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 sale;
        uint8 chain;
        bool approved;
    }
    // Creating list that holds all the objects

    Drop[] public drops;
    mapping (uint256 => address) public users;
    // Adding to the drop objects list

    function addDrop( Drop memory _drop ) public {
        _drop.approved = false;
        drops.push(_drop);  
            uint256 id = drops.length -1;
            users[id] = msg.sender;

// "https://nerdycoderclones.online/metedata/1.png",
// "testcollection",
// "this is my drop for the month",
// "twitter",
// "https://nerdycoderclones.online/",
// "fasfas",
// "0.03",
// "22",
// 1635790237,
// 1635790237,
// 1,
// false



    }
    // Getting the drop object list

    function getDrop() public view returns (Drop[] memory){
        return drops;
    }

    // Update 

     function UpdateDrop(uint256 _index, Drop memory _drop) public {

            require(msg.sender == users[_index],"You are not the owner of this drop");
            _drop.approved = false;
            drops[_index] = _drop;
    }
 // Approve an nft drop object to be displayed 
    
        function approveDrop(uint256 _index) public onlyOwner{
            Drop storage drop = drops[_index];
            drop.approved = true; 
        }

}