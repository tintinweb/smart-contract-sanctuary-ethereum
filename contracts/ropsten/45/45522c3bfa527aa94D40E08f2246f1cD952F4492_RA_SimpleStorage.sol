// SPDX-Lisence_Identifer: MIT

pragma solidity 0.5.16;

contract RA_SimpleStorage {
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;
    mapping(string => uint256) public nametoFavoriteNumber;

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nametoFavoriteNumber[_name] = _favoriteNumber;
    }

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
}