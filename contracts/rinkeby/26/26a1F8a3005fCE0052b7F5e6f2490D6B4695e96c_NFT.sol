// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
//npx hardhat compile

contract NFT {
    struct People{
        uint256 favNumber;
        string name;
    }
    uint price = 0.0001 ether;
    People[] public people;
    address public owner;
    mapping(string => uint256) public nameToFavNumber;

    constructor() public {
        owner = msg.sender;
    }

    function addPerson(string memory _name, uint256 _favNumber) public {
        people.push(People({favNumber: _favNumber, name : _name}));
        nameToFavNumber[_name] = _favNumber;
    }

    function fund() public payable {
        require(msg.value >= price, "The price is 0.001 ether");
    }

    modifier onlyOwner{
        require(msg.sender == owner, "Only owner can call it");
        _;
    }

    function withdraw() onlyOwner public {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }
}