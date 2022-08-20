// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // solidity version being used

// solidity code is compiled to EVM(Ethereum virtual machine)
// the evm can then be deployed to a network that supports EVM

// a contract is to solidity what a class is to an oop language
contract SimpleStorage {
    // boolean, uint(unsigned int), int, address(wallet address), bytes(bytecode)
    // string
    // uint[bytes] eg uint256 - allocate 256 bytes
    // bytes[bytes] eg bytes[8] - allocate 8 bytes for the variable max = 32 bytes
    // default int value is 0

    // public properties are getters behind the scenes
    // they are view functions 'behind the scenes'
    uint256 public favoriteNumber;

    struct Person {
        string name;
        uint256 age;
    }

    Person public p = Person({name: "George", age: 22});
    Person[] public people;
    mapping(string => uint256) public personAges;

    // structs, mappings and arrays need to be given memory/calldata keyword
    function addPerson(string memory name, uint256 age) public {
        Person memory person = Person({name: name, age: age});
        people.push(person);
        personAges[name] = age;
    }

    // virtual is used when a function can be overriden by inheriting contracts
    function store(uint256 _favNum) public virtual {
        favoriteNumber = _favNum;
    }

    // view and pure don't spend gas when called outside a contract function
    // since they are reading from the blockchain and not performing any modifications
    // however, calling a view function from within a contract function will cost gas
    // view - reads state. It doesn't modify state
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // pure - disallow reading from blockchain state(maybe return some static value)
    function algo() public pure returns (uint256) {
        return (1 + 1);
    }
}

/**
 * areas where data can be stored:
 * - stack
 * - memory - exists temporarily(scope is limited to function, variables can be modified)
 * - storage - exists outside the function(it will be around even after the function
 *             completes execution)
 * - calldata - exists temporarily(scope is limited to function. Used when the variable
 *              will not be assigned a new value[a const variable])
 * - code
 * - logs
 */
// public variables are stored in storage ie they are <type> public storage <name>
// implicitly
//*~* - statement not clearly understood