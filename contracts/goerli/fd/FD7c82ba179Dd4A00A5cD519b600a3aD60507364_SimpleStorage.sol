//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// EVM, Ethereum Virtual Machine
// Avalanche, Fantom, Polygon

contract SimpleStorage {
    // Solidity Data Types or just "Types" are boolean, uint, int, address, bytes
    // This (uint256 favoriteNumber;) gets intialized to zero!
    // <- This means that this section is a comment and doesn't compile or run with the code!
    uint256 favoriteNumber;

    // When you don't give a visibility specifier to funcions or variables it automatically gets deployed as internal

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //uint256[] public favoriteNumbersList;
    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // 2 functions don't spend gas to run are view & pure because they don't cause a transaction. Free unless called within a function that costs gas
    // view function disallows any modification of state. pure function disallow any modification state and reading of the blockchain
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata, memory, storage places where data is stored in Solidity
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}