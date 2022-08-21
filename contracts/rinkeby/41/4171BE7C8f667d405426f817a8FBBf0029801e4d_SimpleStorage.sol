//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
contract SimpleStorage {
    // contents of the SimpleStorage contract
    // data tyoes: boolean, uint, int, address, bytes, strings
    uint256 favoriteNumber;
    People public person  = People({favoriteNumber:2, name:"John"});
    People[] public people;
    mapping(string => uint256) public nameToFavoriteNumber;
    // list of variables in solidity get automaically indexed 
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumber) public virtual{
        favoriteNumber = _favoriteNumber;
        favoriteNumber = favoriteNumber * favoriteNumber;
    }

    function getFavoriteNumber() public view returns(uint256){
        return favoriteNumber;
    }
    function addPerson(string memory _name, uint256 _favoriteNumber) public{
        People memory newPerson = People(_favoriteNumber,_name);
        people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

}