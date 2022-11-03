// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 public favNum;
    mapping(string => uint256) public nameToFavNum;
    struct People {
        string name;
        uint256 favNum;
    }
    People[] public listOfPeople;

    function storeFavNum(uint256 _favNum) public virtual {
        favNum = _favNum;
    }

    function retrieveFavNum() public view returns (uint256) {
        return favNum;
    }

    function addPerson(string memory _name, uint256 _favNum) public {
        listOfPeople.push(People(_name, _favNum));
        nameToFavNum[_name] = _favNum;
    }
}