//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    uint256 public favoriteNumber;

    struct PeopleWithFavoriteNumber {
        string name;
        uint256 favoriteNumber;
    }

    PeopleWithFavoriteNumber[] public people;
    mapping(string => uint256) public nameToFavNum;

    function setFavoriteNumber(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retriveFavoriteNumber() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPersonWithFavNum(string memory _name, uint256 _favoriteNumber)
        public
    {
        people.push(PeopleWithFavoriteNumber(_name, _favoriteNumber));
        nameToFavNum[_name] = _favoriteNumber;
    }
}