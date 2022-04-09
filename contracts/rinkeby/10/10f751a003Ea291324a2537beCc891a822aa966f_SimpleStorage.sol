//SPDX-License-Identitfier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favoriteNumber;
    event storedNumber(
        uint256 indexed oldNumber,
        uint256 indexed newNumber,
        uint256 addedNumber,
        address sender
    );

    function store(uint256 _favoriteNumber) public {
        emit storedNumber(
            favoriteNumber, 
            _favoriteNumber,
            favoriteNumber + _favoriteNumber,
            msg.sender);
        favoriteNumber = _favoriteNumber;
    }
}

// store_tx.events gives us this result:
// {'storedNumber': 
// 		[
// 			OrderedDict
// 			([
// 				('oldNumber', 0), //indexed
// 				('newNumber', 3), //indexed
// 				('addedNumber', 3), //not indexed and we can read what it is because we have a contract abi
// 				('sender', '0x66aB6D9362d4F35596279692F0251Db635165871')//not indexed and we can read what it is because we have a contract abi
// 			])
// 		]
// }