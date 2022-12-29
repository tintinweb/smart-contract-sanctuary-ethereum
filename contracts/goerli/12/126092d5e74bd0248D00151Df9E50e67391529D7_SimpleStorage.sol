// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SimpleStorage {
    // Will be initialized to 0
    // Visibility in Solidity
    // public -> Can be called internally or via messages
    // external-> Only can be called by external contracts
    // internal-> Can only be accessed internally (within or contract deriving)
    // private -> Only within the contract
    // Default is internal
    struct People {
        string name; // index 0
        uint256 favNumber; // index 1
    }
    uint256 public number;
    People public person = People({name: "Ramesh", favNumber: 1});
    // Arrays
    uint256[] public numbers;
    // Map => Key value pair
    mapping(uint256 => string) public numberToName;

    function addNumber(uint256 _number) public {
        numbers.push(_number);
    }

    // memory -> Temporary storage
    // storage -> Permanent storage
    function addPerson(string memory _name, uint256 _favNumber) public {
        numberToName[_favNumber] = _name;
    }

    function store(uint256 _favNumber) public {
        number = _favNumber;
    }

    // view -> Only Reading not a state change not any math
    // pure -> Only does maths or computations does not do the state change on the blockchain
    function retrieve() public view returns (uint256) {
        return number;
    }
}