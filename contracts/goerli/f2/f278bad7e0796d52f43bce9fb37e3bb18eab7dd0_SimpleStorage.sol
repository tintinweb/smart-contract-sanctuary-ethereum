/**
 *Submitted for verification at Etherscan.io on 2022-09-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // welke versie je wilt coden

contract SimpleStorage {
    uint favoriteNumber;

    mapping(string => uint) public nameToFavoriteNumber; // zoeken van string naar int

    function store(uint _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint) {
        return favoriteNumber;
    }

    struct People {
        // constructor
        uint favoriteNumber; //  opzoeken op nummer in volgorde
        string name;
    }

    People[] public people;

    // calldata tijdige memory die niet kan veranderd worden, memory tijdelijk en wel kan veranderen, storage niet tijdelijk maar altijd
    function addPerson(string memory _name, uint _favoriteNumber) public {
        People memory newPerson = People(_favoriteNumber, _name);
        people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}

// 0xd9145CCE52D386f254917e481eB44e9943F39138