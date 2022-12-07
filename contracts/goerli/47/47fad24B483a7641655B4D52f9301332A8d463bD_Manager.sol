// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Manager{
    address[] private _products;
    address private owner;

    modifier onlyOwner{
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    constructor(){
        owner = msg.sender;
    }

    function getTotal() public view returns(uint256){
        return _products.length;
    }

    function getProducts() public view returns(address[] memory){
        return _products;
    }

    function setProducts(address _addr) onlyOwner public returns(bool) {
        _products.push(_addr);
        return true;
    }

}