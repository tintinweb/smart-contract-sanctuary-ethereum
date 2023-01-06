// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract SimpleStorage {
    //@dev this will get initialized to 0
    uint256 public favoriteNumber;
    mapping(string => uint256) public nameToFavoriteNumber;
    // bool favoriateBool = true;
    // string favoriteString = "Gerard";
    // int256 favoriteInteger = -11;
    //address favoriteAddress = 0x75hhjjsduurkekeugjkeeitkei;

    struct People {
        string name;
        uint256 favoriteNumber;
    }

    // uint256[] public favoriteNumberList;
    People[] public people;

    // mapping(string => uint256) public useNameToRetrieveAge;

    //People  person1 = People({id: 1, name: "Gerard", age: 23});

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_name, _favoriteNumber));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}