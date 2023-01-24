// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7 ;

contract SimpleStorage {
    // initialized to zero by default
    uint256 public favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    mapping(string => uint256) public nameToFavoriteNumber;

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view, pure
    function reterieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // people.push(People(_favoriteNumber, _name));

        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        people.push(newPerson);

        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}
// 0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8