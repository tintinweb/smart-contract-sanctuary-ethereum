// SPDX-License-Identifier:MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber; //somekind of dictionary.t
    // adding value to struct
    // People public person = People({favoriteNumber:2,name:"sahar"});
    // People public person = People({favoriteNumber:3,name:"hamed"});

    //uint256[] public favoriteNumberList;
    //list of value for People;
    People[] public people;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // People memory newPerson = People(_favoriteNumber,_name); first way
        people.push(People(_favoriteNumber, _name)); //second way

        //take name return number
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}