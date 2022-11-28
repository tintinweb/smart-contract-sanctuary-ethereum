//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7; // We need to put the Solidity version at top

// we can also put >= 0.8.7 <0.9 for between versions

contract SimpleStorage {
    // boolean, unit (unsigned integer - non negative), int, address, bytes, strings
    // Above are the variable types

    uint256 public favoriteNumber;

    // Not setting the variable will initialized to default value 0

    // VM - Virtual Machine is a fake local blockchain to deploy smart contracts
    // All smartcontracts also have an address like the wallet address
    //0xd9145CCE52D386f254917e481eB44e9943F39138 - contract address
    //Everytime the contract is deployed - a new contract address is created
    // We cannot delete a contract once deployed

    //functions / methods
    // view, pure functions do not make any transactions (so no gas 😃)

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        // Calling a view or pure function from a function that costs gas - gas will be applied
        // this is because we are doing computation in blockchain to call the view or pure function
    }

    // View funcion
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // pure function - always give same o/p for same i/p
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return (a + b);
    }

    // Structs - are like objects to craete a bucket of variables.
    //In solidity we need to define the objects first
    struct people {
        uint256 rollNo;
        string name;
    }
    // I can now use people as the variable type

    people public class_A = people({rollNo: 2, name: "Sai"});

    // We can also create an array of objects

    //uint256[] public nos; //way to create a number array **just for test**

    people[] public allClasses; // array of people objects
    //[] - dynamic array, [3] - static array - has only 3 items

    //Creating a function to add to all classes

    //mapping - a datastructure where a key is mapped to a single value

    //Mapping is useful to map one variable in struct to another so we can track it (refer addingInfo function)

    mapping(string => uint256) public nameTorollno;

    function addingInfo(uint256 _rollNo, string memory _name) public {
        // allClasses.push(people(_rollNo, _name)); - 1st way

        // We can also create a variable and then to push to allClasses

        people memory newData = people({rollNo: _rollNo, name: _name});
        allClasses.push(newData); // 2nd way

        //mapping

        nameTorollno[_name] = _rollNo;
    }

    // Calldata, memory and storage
    // Calldata and memory means that the variable only exists temporarily during the transaction
    // Storage variable exists even outside the functions - like favoriteNumber
    // Calldata variables are like consts - cannot be modified
}

// Contract dployed to rinkeby - 0x9B24d09003A4D05d632636E10b331b5d379Fd7E9