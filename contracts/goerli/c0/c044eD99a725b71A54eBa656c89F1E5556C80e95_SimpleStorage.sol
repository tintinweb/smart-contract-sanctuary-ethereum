// SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

// means above and equal version

contract SimpleStorage {
    //variables
    uint256 favoriteNumber;

    //mapping
    mapping(string => uint256) public nameToFavooriteNumber;

    //structures -> custom datatype
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People public person = People({favoriteNumber: 4, name: "Pattric"});

    // List that store sequence of data
    // dynamic array
    // [3] static size
    People[] public peoples;

    // string is array of bytes
    // solidity know about uint256
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        peoples.push(newPerson);
        nameToFavooriteNumber[_name] = _favoriteNumber;
    }

    // Functions
    // virtual -> makes a function overidable
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        // however if called inside a gas constly function it will consume gas
        retrieve();
    }

    // View & Pure -> disaalow any modification of blockchain
    // do not consume gas
    // View VS Pure -> View allow only read from blockchain , Pure disallow state reading from blockchain

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // array , struct , memory -> only these need data location to be specified

    // calldata , memory -> variable is only gona exist temporarily
    // calldata -> if modification is not expected
    // memory -> temp var that can be modified
    // storage -> exist event outside function / transaction
}