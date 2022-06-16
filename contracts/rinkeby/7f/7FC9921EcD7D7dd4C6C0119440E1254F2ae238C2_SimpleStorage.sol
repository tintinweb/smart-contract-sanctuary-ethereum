/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract SimpleStorage {

    uint256 public favouriteNo;
    
    struct People {
        uint256 favouriteNo;
        string name;
    }

    People[] public person;
    mapping(string => uint256) public nameToFavoriteNumber;

    function store (uint _favouriteNo) public {
        favouriteNo = _favouriteNo;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNo;
    }

    function addPerson (string memory _name, uint256 _favouriteNo) public {
        person.push(People({favouriteNo : _favouriteNo, name : _name}));
        nameToFavoriteNumber[_name] = _favouriteNo;
    }
    
}