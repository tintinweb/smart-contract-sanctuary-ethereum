// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.8;             //0.8.7 or greater than that will work
pragma solidity ^0.8.8; //0.8.7 will work

// pragma solidity >=0.8.7 <0.9.0      //0.8.7 to less than 0.9.0 will work

// EVM, Ethereum Virtual Machine
// Avalanche, Fantom, Polygon

contract SimpleStorage {
    //boolean, uint, int, address, bytes
    uint256 public favoriteNumber; //Default value is zero if not explicitly initialized

    People public person = People({favoriteNumber: 2, name: "Patrick"});

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // uint256[] public favoriteNumbersList

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //View and pure functions doesnt actually have to spend gas to run
    //View - disallows any modification of the state
    //Pure - disallows modifications as well as reading storage
    // costs gas if pure and view functions are called from a contract

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function add() public pure returns (uint256) {
        return (1 + 1);
    }

    // calldata     - temporary variables that cannot be modified
    // memory       - temporary variables that can be modified
    // storage      - permanent variables that can be modified

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}

// 0xd9145CCE52D386f254917e481eB44e9943F39138
//Composability - The ability of contracts to interact seamlessly interact with each other