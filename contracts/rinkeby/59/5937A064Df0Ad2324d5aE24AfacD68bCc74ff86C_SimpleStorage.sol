// SPDX-License-Identifier : MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct People {
        uint256 favNumber;
        string name;
    }

    People[] public AllRecordOfPeople;
    mapping(uint256 => string) public PeopleNUmberMapping;

    function AddPeople(string memory _Name, uint256 _FavNumber) public {
        AllRecordOfPeople.push(People(_FavNumber, _Name));
        PeopleNUmberMapping[_FavNumber] = _Name;
    }

    function setValue(uint256 _newFavoriteNumber) public {
        favoriteNumber = _newFavoriteNumber;
    }

    function getFavNUmber() public view returns (uint256) {
        return favoriteNumber;
    }
}