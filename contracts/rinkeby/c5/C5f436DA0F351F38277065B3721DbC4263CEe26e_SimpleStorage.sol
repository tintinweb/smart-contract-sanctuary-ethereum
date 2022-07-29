// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// Evm - Ethereum virtual machine
// avalanche , fantom , polygom -Evm supported blockchains
contract SimpleStorage {
    //Boolean,uint,int,address,bytes

    // uint myUnSignedNum=23;

    // // strings are also bytes object but only for text. they dont get converted to bytes object
    // // bytes object is baiscally set of numbers and letters which represents something
    // // example 0x12334jfn3

    // string myString="Hello, world";

    // //when we dont initialize this it is automatically set to 0
    // int256 signedNum=-23;
    // address myAddress=0x27882e9E878045f681aaFdF154e50B870C6e44Bf;

    // //Maxium size of bytes is 32. looks like text but can get converted into bytes

    // bytes32 myFavByte="hi world";

    // By default the visibility is set to internal
    uint256 public favNumber;

    function store(uint _favNumber) public virtual {
        favNumber = _favNumber;
        // uint num2;
    }

    // 0xd9145CCE52D386f254917e481eB44e9943F39138

    // num2 is not accessible outside the function because its inside a bloc {...}

    //Two types of functions - pure,view

    // view doesnt modify the state of the contract but reads it
    // pure functions dont modify or read the state .
    // when we call view or pure functions no gas is spent
    // only when the state is modified gas is spent
    function retreive() public view returns (uint256) {
        return favNumber;
    }

    function add() public pure returns (uint256) {
        return (1 + 1);
    }

    // Arrays , structs, mapping - special types
    struct People {
        uint256 favNumber;
        string name;
    }
    // People public person=People({favNumber:3,name:"vignesh"});

    // // Below is an arbitrary array - the one with no size
    People[] public people;

    // Mapping type
    mapping(string => uint) public nameToFavNumber;

    // //Fixed size
    // People[3] public people;

    //calldata,memrory,storage
    function addToPeople(uint _favNumber, string calldata _name) public {
        // people.push(People({favNumber:_favNumber,name:_name}));
        people.push(People(_favNumber, _name));
        nameToFavNumber[_name] = _favNumber;
    }
}