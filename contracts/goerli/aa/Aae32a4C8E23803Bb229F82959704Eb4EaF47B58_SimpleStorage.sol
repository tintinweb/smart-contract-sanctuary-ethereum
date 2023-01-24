/**
 *Submitted for verification at Etherscan.io on 2023-01-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // 0.8.12

contract SimpleStorage {
    // bool hasFavoriteNumber = false;
    uint256 favoriteNumber = 123;
    // int neFavoriteNumber = -10;
    // string favoriteNumberInText = "Five";
    // address myAddress = 0x7EF2e0048f5bAeDe046f6BF797943daF4ED8CB47;
    // bytes32 favoriteBytes = "cat"; // 0x345t345345345

    mapping(string => uint256) public nameToFavoriteNumber;
    
    // People public person = People({favoriteNumber: 1, name: "Jack"});
    
    // uint256 public favoriteNumbers = [];
    People[] public people;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumer) public virtual {
        favoriteNumber = _favoriteNumer;
        // retrive() // gets cost, because it reads from the Blockchain
    }

    // view & pure function do not take cost
    function retrive() public view returns(uint256) {
        return favoriteNumber;
    }
    // function add() public pure returns(uint8){
    //     return 1+1;
    // }

    function addPerson(string memory _name, uint256 _favoriteNumer) public {
        people.push(People({favoriteNumber: _favoriteNumer, name: _name}));
        nameToFavoriteNumber[_name] = _favoriteNumer;
    }
}

// 0x7EF2e0048f5bAeDe046f6BF797943daF4ED8CB47