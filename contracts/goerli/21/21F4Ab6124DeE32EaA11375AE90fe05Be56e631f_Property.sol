// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

contract Property{
    uint private price;
    address public owner;
    constructor() {
        price = 0;
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require (msg.sender == owner);
        _;
    }

    function changeOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function setPrice(uint _price)public {
        price = _price;
    }
    function getPrice() public view returns(uint){
        return price;
    }
}