// Everything is written in Remix editor (https://remix.ethereum.org/)

// pragma solidity 0.8.7; // it uses solidity version 0.8.7
// pragma solidity ^0.8.7; // it uses solidity version 0.8.7 and above
// pragma solidity >=0.8.7 <=0.9.0 // it uses solidity version between 0.8.7 and 0.9.0 (both inclusive)

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    //  boolean, uint, int, address, bytes
    // bool hasFavoriteNumber = true;
    // uint favoriteNumber = 123; // uint8 will use 8 bit ans similarly uint256 will use 256 bit
    // int favNumber = 5;
    // string favNumText = "Five";
    // address myAddress= 0xAdE2E398779C584eB6C34d06C682A3f432C9Af2F;
    // bytes32 favBytes = "cat";

    // you need to specify public for being viewed from outside
    // the types are public, private, internal, external
    uint256 public favNumber;

    // creating own data types
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // array of people (dynamic size)
    People[] public people;
    // array of people fixed size ==> People[3] public people;

    // creating a map
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favNumber = _favoriteNumber;
    }

    // view function doesn't cost ether as well as doesn't allow any calculation inside
    // other are view, pure(disallow reading from blockchain either), gas calling function
    function retrieve() public view returns (uint256) {
        return favNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    // notes
    // More stuff costs more ether
    // view and pure functions will cost gas if called by gas calling function
    // evm - calldata(data is stored temp, data_type modification is not allowed), 
    // memory(data is stored temp, data_type modification is allowed), 
    // storage(data is store pernamentely, data_type modification is allowed).
    // evm is required for struct, array or mapping types

}

    // transaction hash:- 0x7f3410afe0824e624af5d1cffc2e7573a6a74ff4cfb5f0f0970b3b4f648f8e04