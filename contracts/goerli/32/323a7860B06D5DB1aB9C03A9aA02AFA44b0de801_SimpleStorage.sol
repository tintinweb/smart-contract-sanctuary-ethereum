// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    //boolean, uint, int, address, bytes
    uint256 favouriteNumber;

    People person = People({favouriteNumber: 2, name: "Sahil"});

    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    // uint256[] public favouriteNumbersList;
    People[] public people;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
        retrieve();
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }

    //0xd9145CCE52D386f254917e481eB44e9943F39138

    //calldata, memory, storage
}