// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    // boolean, uint, int has negative value, address, bytes

    uint256 hasFavoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        hasFavoriteNumber = _favoriteNumber;
    }

    // view, pure
    function retrive() public view returns (uint256) {
        return hasFavoriteNumber;
    }

    // function addPerson(string memory _name, uint256 _favoriteNumber) public {
    //     people.push(People(_favoriteNumber, _name));
    //     nameToFavoriteNumber[_name] = _favoriteNumber;
    // }

    // function removePerson() public {
    //     people.pop();
    // }
    // function lengthArr() public view returns(uint256){
    //     return people.length;
    // }

    // calldata, memory, storage
}