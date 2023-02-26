/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

//SPDX-License-Identifier:MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    //by default intialized with zero
    uint256 favoriteNumber;

    //public visibility
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //creating structure of People type
    struct People {
        string name;
        uint256 favoriteNumber;
    }
    //creating array of People Type;
    People[] public PeopleArray;
    //creating mapping of name to favoritenumber
    mapping(string => uint256) public nametofavoritenumber;

    function AddPeople(
        string memory _name,
        uint256 _favoriteNumber
    ) public virtual {
        PeopleArray.push(People(_name, _favoriteNumber));
        nametofavoritenumber[_name] = _favoriteNumber;
    }
}