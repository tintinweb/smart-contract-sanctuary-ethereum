// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract SimpleStorage {
    //external, public, private, internal (default, if not mentioned)

    uint256 number; //initialized to 0 by default
    // bool boolean = true;
    // string str = "String";
    // int256 negativeNumber = -2;
    // address addr = 0x4D1Acf49f1c7cCBC84A5FDd3120742F3C2151bAf;
    // bytes32 bytStr = 'cat';

    struct People {
        uint256 favNum;
        string name;
    }

    People[] public people; //dynamic array
    mapping(string => uint256) public nameNumberMap; //returns 0 (default value) if key not found

    People public person = People({favNum: 2, name: "aakash"});

    //
    function store(uint256 _favNum) public virtual {
        number = _favNum;
    }

    //view functions - read only, view only
    //pure funcions - do some type of math, do not read or write data
    //they don't really tansact on the blockchain, do not cost gas, can't update the state of the blockchain
    //if retrieve is called from outside the contract, it doesn't cost any gas
    //but if retrieve is called from a pure function, then the cost of retrieve function is added
    function retrieve() public view returns (uint256) {
        return number;
    }

    //memory holds it only in memory, storage means keep it forever.
    function addPerson(string memory _name, uint256 _favNum) public {
        // people.push(People({ name: _name, favNum: _favNum})); out of order mention the var name
        // if we directly create the object, we don't even need to hold it in memory
        // People memory newPerson = People(_favNum,_name);
        people.push(People(_favNum, _name)); //in order, can ignore
        nameNumberMap[_name] = _favNum;
    }
}

//EVM can access and store information in six places
//stack, memory, storage, calldata, code, logs

//calldata, memory, storage
/*
. memory - variable exists temporarily in memory
. storage - exists outside the function as well, generally we don't need function variables to be stored, hence they're
specified as memory
. calldata - if you don't change the value of the variable yourself, that variable can be marked as calldata
memory variables can be modified, calldata cannot be modified within the function, storage is permanent but can be changed

Data location can only be specified for arrays, struct, or mapping types, not for uint int types, primitive types
String is an array of bytes hence we need to mention memory or calldata

for a function variable we cannot assign "storage" keyword because solidity knows this is a function variable and
it does not make sense to store it in memory
*/