/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract APCHboos{

    address public owner;

    struct Drop{
        string imageUrl;
        string descreption;
        string name;
        string community_1;
        string community_2;
        string community_3;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 sale;
        uint8 chain;
        bool approve;
    }

    Drop[] public Drops;
    mapping (uint256 => address) public users;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner. ");
        _;
    }
    function getDrop() public view returns (Drop[] memory){
        return Drops;
    }

    function AddDrop(Drop memory _drop) public {
        _drop.approve = false;
        Drops.push(_drop);
        uint256 id = Drops.length -1;
        users[id] = msg.sender;
    } 

    function updateDrop(uint256 _index) public onlyOwner {
        Drop storage drop = Drops[_index];
        drop.approve = true;
    }

    
    
}