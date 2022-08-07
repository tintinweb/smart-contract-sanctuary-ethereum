/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // the version. always the first line in a solidity contract

//another way is "pragma solidity ^0.8.7"
//or >=0.8.7<0.9.0

//to write a contract

contract SimpleStorage {
    //bool , uint, int , address , bytes, string
    //This gets initiallized to the null value which is apparently zero!
    uint256 public favoriteNumber;

    //array
    People[] public people;
    //uint256[] public favoriteNumberList;

    //struct

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    //mapping
    mapping(string => uint256) public nameToFavNumber;

    //Solidity function
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        //0xD7ACd2a9FD159E69Bb102A1ca21C9a3e3A5F771B
    }

    //view and pure type functions , don't spend gas upon being called
    //with view, you won't modify the blockchain, and you cannot modify the values, in
    //addition to what view does, pure won't let you to read from the blockchain either
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string calldata _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        //or People memory person = People({favoriteNumber: _favoriteNumber , name = _name});
        nameToFavNumber[_name] = _favoriteNumber;
    }
}