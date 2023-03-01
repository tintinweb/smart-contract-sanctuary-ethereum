//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract NameToFavoriteNumber {
    mapping(string => uint16) public nameToFavoriteNumber;

    function enterUser(string memory _name, uint16 _favoriteNumber) public {
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function fetchFavoriteNumber(
        string memory _name
    ) public view returns (int16) {
        if (nameToFavoriteNumber[_name] == uint256(0x0)) {
            return -1;
        }
        return int16(nameToFavoriteNumber[_name]);
    }
}