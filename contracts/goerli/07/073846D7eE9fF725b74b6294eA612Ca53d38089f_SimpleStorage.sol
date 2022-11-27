// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// EVM, Ethereum Virtual Machine
// Avalanche, Fantom, Polygon

contract SimpleStorage {
    //boolean, uint, int, address, bytes
    // bool hasFavNumber = true;
    // string favouriteNumberInText = "Five";
    // int256 favouriteInt = -5;
    // address myAddress = 0x0D3B3fcDe104699FF91AE8D0cEf8569af60C0aD3;
    // bytes32 favouriteBytes = "cat";

    // Smart Contract also has a address 0xd9145CCE52D386f254917e481eB44e9943F39138

    // This gets initialized to zero
    uint256 favNumber;

    mapping(string => uint256) public nameToFavNumber;

    // creating a dynamic array
    People[] public people;

    // structure creating a new type
    struct People {
        uint256 favNumber;
        string name;
    }

    // overridable function should have virtual keyword in it
    function store(uint256 _favouriteNumber) public virtual {
        favNumber = _favouriteNumber;
    }

    // calldata, memory, storage
    // calldata is temporary but cannot be modified
    // memory is temporary but can be modified
    // Storage is permanent which can be modified. If not explicitly defined it is automatically storage

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        People memory newPerson = People({
            favNumber: _favouriteNumber,
            name: _name
        });
        people.push(newPerson);
        nameToFavNumber[_name] = _favouriteNumber;
    }

    // view (Read states from the contract, Dissallows modification), pure (dissallows reading and modifying from blockchain)
    // these function does not requires gas
    // if any other non view or pure function calls view or pure function it requires gas
    function retrieve() public view returns (uint256) {
        return favNumber;
    }
}