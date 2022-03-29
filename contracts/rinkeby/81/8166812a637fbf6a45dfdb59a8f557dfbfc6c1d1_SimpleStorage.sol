/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.6.0;
contract SimpleStorage {
    uint256 favoriteNumber; //equal to uint favoriteNumber = 0;
    event pp(string sname);

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }
    function get() public view returns(uint){
        return favoriteNumber;
    }

    function addpeople(uint256 _favoriteNumber, string memory _name) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
        emit pp(_name);
    }

}