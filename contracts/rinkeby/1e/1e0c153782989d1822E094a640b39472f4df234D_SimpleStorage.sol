/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8; //^0.8.7 ; >=0.8.7 < 0.9.0

contract SimpleStorage {

    //init is 0
    uint256 public favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;
    People public person = People({favoriteNumber: 2, name: "Pablo"});

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public peopleList;


    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns(uint256){
        return favoriteNumber;
    }

    function addStuff() public pure returns(uint256){
        return 1 + 1;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        peopleList.push(newPerson);

        nameToFavoriteNumber[_name] = _favoriteNumber;
        //peopleList.push(People(_favoriteNumber, _name));
    }
}