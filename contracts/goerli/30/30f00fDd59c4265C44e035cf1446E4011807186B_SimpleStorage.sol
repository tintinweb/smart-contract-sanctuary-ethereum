// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // Solidity version

// EVM, ehthereum virtual machine
contract SimpleStorage {
    // This gets initialized as zero!
    uint256 public favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;
    
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people; // dynamic array
    // People[4] public people; // static array

    // uint256[] public favoriteNumbers;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // pure
    function add() public pure returns (uint256) {
        return 1 + 1;
    }

    // struct, arrays or mapping need memory or calldata keywords
    // calldata - temporary but immutable
    // memory - temporary but mutable
    // storage - permanant but mutable
    // function params can only specify either calldata or memory
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({favoriteNumber : _favoriteNumber, name : _name});
        people.push(newPerson);

        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function findPersonByName(string memory _name) public view returns (People memory) {
        uint256 temp = 0;

        People memory currentPerson;
        while (temp < people.length) {
            currentPerson = people[temp];

            if (compareStrings(currentPerson.name, _name)) {
                return currentPerson;
            }
            temp++;
        }

        currentPerson = People(0, "");
        return currentPerson;
    }
}