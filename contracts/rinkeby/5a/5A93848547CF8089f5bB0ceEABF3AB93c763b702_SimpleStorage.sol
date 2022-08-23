// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    //gets initialized to zero
    uint256 public favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;
    struct People {
        //capitalized to denote struct
        uint256 favoriteNumber;
        string name;
    }
    //uint256[] public favoriteNumberList;
    //type[] to initialize array of a determined type
    People[] public people; //lowerCase to denote variable (array of people)

    //view,pure don´t cost gas
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function store(uint256 _favoriteNumber) public virtual {
        //virtual allows overriding with inheritance
        favoriteNumber = _favoriteNumber;
    }

    //memory and calldata for variables that are not stored and storage for variables that can be used outside of a given context(for arrays(strings), mappings, etc)
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //People memory newPerson = People({favoriteNumber : _favoriteNumber, name : _name});
        people.push(People(_favoriteNumber, _name)); //we add a struct of type People to array people
        //people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}