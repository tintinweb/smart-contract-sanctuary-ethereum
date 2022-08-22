// SPDX-License-Identifier: MIT
pragma solidity 0.8.8; // this is one of the ways to tell the code the version

contract SimpleStorage {
    // this gets initialiazed with zero
    uint256 public favoriteNum;

    mapping(uint256 => string) public nameToFavNum;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNum = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNum;
    }

    struct People {
        uint256 favoriteNum;
        string name;
    }
    People[] public people;

    function addperson(uint256 _favoriteNum, string memory _name) public {
        //People memory newPerson = People({favoriteNum: _favoriteNum, name: _name});
        //people.push(newPerson);
        people.push(People(_favoriteNum, _name));
        nameToFavNum[_favoriteNum] = _name;
    }

    //function store(uint256 _favoriteNum) public {
    // favoriteNum= _favoriteNum;
}