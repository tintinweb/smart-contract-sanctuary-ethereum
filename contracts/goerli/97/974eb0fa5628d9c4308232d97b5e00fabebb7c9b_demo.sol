/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

contract demo {
    uint public x=10;
    address public owner;
    string[] public categories;

    event cat(string indexed _category);

    modifier onlyOwner(){
        require(owner == msg.sender, "Just Owner!");
        _;
    }

    constructor(){
        owner = msg.sender;
    }


    function login() public view onlyOwner returns(bool){
        return true;        
    }

    function set(uint _x) public{
        x = _x;
    }

    function set2(uint _x) public onlyOwner{
        x = _x;
    }

    function getNum() public view onlyOwner returns(uint){
        return x;
    }

    function addCat(string memory _category) public {
        categories.push(_category);
    }

    function getCat() public view onlyOwner returns(string[] memory){
        return categories;
            
    }
}