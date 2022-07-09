/**
 *Submitted for verification at Etherscan.io on 2022-07-09
*/

// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
    //initialized to 0
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    // uint256[] public anArray;
    People[] public people;
    //初始都是0
    mapping(string => uint256) public nameToFavoriteNumber;

    //virtual是可以被override的意思
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //view/pure dont cost gas fee coz they only read, however when used in func
    //use gas they use cost gas fee
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //storage memory calldata(后两个表示暂时的 storage是永久的比如favoritenumber call不可改mem可改)
    //因为name是array其实，array map struct都需要declare memory或者calldata)
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}