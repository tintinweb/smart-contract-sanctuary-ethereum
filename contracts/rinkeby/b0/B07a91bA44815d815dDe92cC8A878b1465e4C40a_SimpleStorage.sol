// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    string message = "hello";
    uint256 favNum;

    mapping (string => uint256) public nameToFavNum;

    struct People {
        string name;
        uint256 favNum;
    }

    People[] public people;

    function addPerson (string memory _name, uint256 _favNum) public {
        People memory newPerson = People({name: _name, favNum: _favNum});
        people.push(newPerson);
        nameToFavNum[_name] = _favNum;
    }

    function store (uint256 _favNum) public virtual {
        favNum = _favNum;
    }

    // view, pure
    function retrieve () public view returns (uint256) {
        return favNum;
    }

}