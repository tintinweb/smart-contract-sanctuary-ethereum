// SPDX-License-Identifier: MIT

// solidity version
pragma solidity ^0.8.7; // 0.8.12

// EVM, Etherium Virtual Machine
// Avalance, Fantom, Poligone
contract SimpleStorage {
    // bool
    // uint - only positive number, default uint256, default -> 0
    // int - positive 0r negative number
    // address - address
    // bytes

    //VISIBILITY, default : internal
    // public : externally and internally, it also create getter and setter method
    // private : only visible to current contract
    // external: only visible externally(only for functions)
    // internal: only visible internally

    // default value will be zero
    uint256 public favNumber;

    // virtual will give permission to override this function
    function store(uint256 _favNumber) public virtual {
        favNumber = _favNumber;

        // this will cost
        //retrive();
    }

    // view, pure keyword used to tell that we are just reading value from the contract so we don't need tp pay gas fee for function retrive
    function retrive() public view returns (uint256) {
        return favNumber;
    }

    // we are just doing math, we only pay gas if we are working with blockchain state
    function add() public pure returns (uint256) {
        return 1 + 1;
    }

    People public person = People({favNumber: 2, name: "Mitul"});

    // struct
    struct People {
        uint256 favNumber;
        string name;
    }

    People[] public peoples;

    // calldata -> same as memery but treat as const, you can't change value of _name if it's calldata
    // memory -> after addPerosn run, we don't need value of _name
    // storage -> default all var is storage
    function addPerson(string memory _name, uint256 _favNumber) public {
        peoples.push(People(_favNumber, _name));
        nameToFavNumber[_name] = _favNumber;
    }

    mapping(string => uint256) public nameToFavNumber;
}
// 0xd9145CCE52D386f254917e481eB44e9943F39138