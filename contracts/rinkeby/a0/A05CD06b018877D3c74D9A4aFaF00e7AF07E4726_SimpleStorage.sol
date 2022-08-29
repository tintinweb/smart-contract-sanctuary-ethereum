// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract SimpleStorage {
    uint256 public favoriteNumber;

    address public owner;

    People[] public people;

    mapping(address => uint256) personToFavoriteNumber;

    struct People {
        address name;
        uint256 favoriteNumber;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner of this contract!");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function store(uint256 _favoriteNumber) public onlyOwner {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(address _person, uint256 _favoriteNumber) public {
        people.push(People(_person, _favoriteNumber));
        personToFavoriteNumber[_person] = _favoriteNumber;
    }
}