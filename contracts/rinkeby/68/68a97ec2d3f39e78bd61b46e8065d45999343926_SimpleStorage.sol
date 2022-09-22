/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// my addy: 0xd9145CCE52D386f254917e481eB44e9943F39138
// smart contract addy: 0x1c91347f2A44538ce62453BEBd9Aa907C662b4bD
contract SimpleStorage {
    // gets automatically intialized to 0 as its default value
    uint256 public myNumber;

    struct People {
        uint256 myNumber;
        string myName;
    }

    mapping(string => uint256) public nameToFavoriteNumber;

    People[] public people;

    function store(uint256 _myNumber) public {
        myNumber = _myNumber;
        retrieve();
    }

    // view and pure does not spend gas fees
    function retrieve() public view returns(uint256) {
        return myNumber;
    }

    function addPerson(string memory _name, uint256 _number) public {
        people.push(People(_number, _name));
        nameToFavoriteNumber[_name] = _number;
    }
}