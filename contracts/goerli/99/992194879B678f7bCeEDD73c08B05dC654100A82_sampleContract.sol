/**
 *Submitted for verification at Etherscan.io on 2022-10-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract sampleContract {
    uint256 public sampleNumber;

    struct People {
        uint256 number;
        string name;
    }

    People[] public people;

    mapping(string => uint256) public nameToFavNumber;

    // People public people = People({number: 5, name: "John"});

    function storeNumber(uint256 _sampleNumber) public {
        sampleNumber = _sampleNumber;
    }

    function retrieve() public view returns (uint256) {
        return sampleNumber;
    }

    function storeStruct(uint256 _num, string memory _name) public {
        people.push(People(_num, _name));
        nameToFavNumber[_name] = _num;
    }
}