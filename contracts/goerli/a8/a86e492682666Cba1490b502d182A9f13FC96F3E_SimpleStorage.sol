// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17;

contract SimpleStorage {
    // max bytes is 32
    // generally good to be explicit on sizing
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }
 
    // view, pure
    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    // calldata (cannot be updated when used, temp), memory (temp, and can be updated the name, storage (can exist outside and modifiable)
    // string is actually just array
    function addPeople(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    
}