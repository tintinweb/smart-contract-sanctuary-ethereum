/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; // Version of solidity that you want to utilize

contract SimpleStorage {
    // Types : boolean, uint, int, address, bytes
    //ex. bool hasFavoriteNumber = true;
    //Below uint gets automatically gets initialized at zero if not a set value.
    uint256 favoriteNumber;
    //ex. People public person = People({favoriteNumber: 2, name: "Patrick"});
    //ex. string FavoriteNumberInText = "Five"
    //ex. int256 FavoriteInt = -5;
    //ex. address MyAddress = 0xaB8415f2EdBB074d61427B0b756D7bE658c32cd4;
    //ex. bytes32 FavoriteBytes = "Cat"; // Bytes normally look like : 0x123456ff7d

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    //uint256() public favoriteNumbersList;
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        //ex. showing increased gas w/ bigger functions ; favoriteNumber = favoriteNumber + 1;
    }

    // storage ; calldata, memory, storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //People memory newPerson = People(_favoriteNumber, _name);
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    // view and pure functions do not require gas ; as they just read the contract
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //function add() public pure returns(uint256) {
    //returns(1 + 1);
    //}

    // Contract Deployed : 0xd9145CCE52D386f254917e481eB44e9943F39138
}