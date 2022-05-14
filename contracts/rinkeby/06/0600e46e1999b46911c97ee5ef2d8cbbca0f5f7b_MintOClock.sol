/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract MintOClock {

    address public owner;

    // define NFT object
    struct Drop {
        string imageURI;
        string name;
        string description;
        string social1;
        string social2;
        string websiteURI;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 sale;
        uint8 chain;
        bool approved;
    }

    // create list to hold items
    Drop[] public drops;
    mapping(uint256 => address) public users;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require (msg.sender == owner, "You are not the owner.");
        _;
    }
    //get NFT drop objects list
    function getDrops() public view returns(Drop[] memory) {
        return drops;
    }
    //add/remove objects from list
    function addDrop(Drop memory _drop) public {
        _drop.approved = false;
        drops.push(_drop);
        uint256 id = drops.length - 1;
        users[id] = msg.sender;
    }

    function updateDrop(uint256 _index, Drop memory _drop) public {
        require(msg.sender == users[_index], "You are not the owner of this project!");
        _drop.approved = false;
        drops[_index] = _drop;
    }
    //approve objects to display
    function approveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;
    }
 

}