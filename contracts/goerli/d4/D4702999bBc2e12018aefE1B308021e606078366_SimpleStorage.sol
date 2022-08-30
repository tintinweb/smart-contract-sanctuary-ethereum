// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

// EVM : Ethereum Virtual Machine
// Avanlance, Fantom, Polygon

contract SimpleStorage {
    // This gets initialized to zero!
    // <- this mean this section is a comment
    uint256 favoriteNumber;
    // People public person = People({favoriteNumber: 2, name: "Duy"});

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    // uint256[] public favoriteNumbersList;
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view, pure just for reading the contract
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata, memory, storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}