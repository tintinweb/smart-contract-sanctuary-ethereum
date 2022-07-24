/**
 *Submitted for verification at Etherscan.io on 2022-07-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; // 0.8.12

contract SimpleStorage {
    // boolean, uint, int, address, bytes
    // bool, uint256, int256, string, address, bytes32
    bool hasFavoriteNumber = false;
    uint256 public favoriteNumber = 5;
    string favoriteNumberInText = "Five";
    int256 favoriteInt = -5;
    address myAddress = 0xc6CD9637938B65797aa9a2E72a64d999B569CEC0;
    bytes32 favoriteBytes = "cat";

    uint256[] public favoriteNumbersList;
    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    //People public person = People({favoriteNumber: 2, /name: "Patrick"});


    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // Initial value is 0
    uint256 defaultValue;


    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
        retrieve();
    }

    // view , pure doesnt use any gas
    function retrieve() public view returns(uint256){
        return favoriteNumber;
    }

    function add() public pure returns(uint256){
        return(1+1);
    }

    // calldata, memory, storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

}

// 0xd9145CCE52D386f254917e481eB44e9943F39138