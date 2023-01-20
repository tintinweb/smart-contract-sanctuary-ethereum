//SPDX-License-Identifier: MIT

pragma solidity 0.8.7; //

contract SimpleStorage {
    uint256 favoriteNumber; //initialized by default to 0
    mapping(string => uint256) public nameToFavorityNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //view, pure
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        // people.push(newPerson);

        People memory newPerson = People(_favoriteNumber, _name);
        people.push(newPerson);
        nameToFavorityNumber[_name] = _favoriteNumber;
    }
}