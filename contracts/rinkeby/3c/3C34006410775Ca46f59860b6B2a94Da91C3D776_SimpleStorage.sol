// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    // major types in solidity: boolean, uint(unsigned int), int, address, byte

    // favouriteNumber initilized to zero
    // when a variable is set to public a getter and setter method is automatically
    // generated hence the blue button appearing in the contract bit on the left hand side
    uint256 favouriteNumber;

    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    // view and pure functions are not transactions and do not use any gas
    // they do not allow you to modify state or read state from the blockchain
    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}