// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract SimpleStorage {
    uint favoriteNumber;
    address owner;
    User[] public users;
    mapping(string => uint) public nameToFavoriteNumber;

    struct User {
        string name;
        uint amount;
    }

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "you are not an owner!");
        _;
    }

    function applyUser(string calldata _name, uint _amount) public {
        users.push(User(_name, _amount));
        nameToFavoriteNumber[_name] = _amount;
    }

    function retrieve() external view onlyOwner returns (uint) {
        return favoriteNumber;
    }

    function store(uint _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }
}