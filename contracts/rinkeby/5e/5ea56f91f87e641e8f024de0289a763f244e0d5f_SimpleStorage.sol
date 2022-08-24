/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract SimpleStorage {
    
    // this will get initialized to 0!
    uint256 favoriteNumber;
    
    struct People {
        uint256 favoriteNumber;
        string name;
    }
    
    People[] public people;
    mapping(string => uint256) public search;
    //People public person = People({favoriteNumber: 2, name: "Patt"});
    
    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }
    
    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }
    
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        search[_name] = _favoriteNumber;
    }
    
}