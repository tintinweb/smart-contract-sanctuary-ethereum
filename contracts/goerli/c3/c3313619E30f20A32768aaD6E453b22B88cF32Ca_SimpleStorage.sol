//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //use to specify solidity version

contract SimpleStorage {
    //String boolean ,unit,int,address,bytes --->data types
    uint256 favoriteNumber = 5; //default value is 0 256 bits

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function getData() public view returns (uint256) {
        return favoriteNumber;
    }
}
//to compile solidity contract solc is used