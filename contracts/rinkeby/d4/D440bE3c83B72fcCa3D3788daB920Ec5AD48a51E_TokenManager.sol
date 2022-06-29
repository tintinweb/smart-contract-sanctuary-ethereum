/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

contract TokenManager{
    address owner;

    mapping(string => address) token;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addToken(string memory _name, address _address) public onlyOwner returns(bool){
        require(_address != address(0), "That address not exists.");
        require(token[_name] != _address, "That token already exists.");

        token[_name] = _address;

        return true;
    }

    function removeToken(string memory _name) public onlyOwner returns(bool){
        delete token[_name];
        
        return true;
    }

    function getTokenAddress(string memory _name) public view returns(address) {
        return token[_name];
    }
}