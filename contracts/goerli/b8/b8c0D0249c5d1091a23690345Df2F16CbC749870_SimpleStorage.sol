//SPDX-License-identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
    //boolean,uint,int,address,bytes,string
    uint256 public favoriteNumber; //This gets initialized to 0

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //view,pure
    function retrive() public view returns (uint256) {
        return favoriteNumber;
    }

    //0xd9145CCE52D386f254917e481eB44e9943F39138

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}