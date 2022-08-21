// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //Solidity Version to use

contract SimpleStorage {
    // Boolean, uinit, int, address, bytes, string
    // bool hasFavNumber = true;
    // uint256 FavNumber = 88;
    // string hi ="Hi";
    // bytes32 text ="cat";

    // Start now
    // this gets intialized  to 0
    uint256 favNumber;
    mapping(string => uint256) public retrieveFavNumber;
    People public person = People({favNumber: 2, name: "Prachi"});
    struct People {
        uint256 favNumber;
        string name;
    }

    // Array in Solidity
    People[] public people;

    function addPerson(uint256 fN, string memory name) public {
        people.push(People(fN, name));
        retrieveFavNumber[name] = fN;
    }

    function store(uint256 fN) public virtual {
        favNumber = fN;
    }

    // view functions do not spend gas only used to read from contracts
    function retrieve() public view returns (uint256) {
        return favNumber;
    }

    // Pure functions do not change states from block chain onluy reads it hence no gas
    function add() public pure returns (uint256) {
        return 1 + 1;
    }

    // private, public, external, internal(auto)

    // calldata- temp data (cant be modified)
    // Memory - temp data (can be modified) recuire specification for arrays structs and mappings

    // Storage- save above contaract

    // Mapping
}