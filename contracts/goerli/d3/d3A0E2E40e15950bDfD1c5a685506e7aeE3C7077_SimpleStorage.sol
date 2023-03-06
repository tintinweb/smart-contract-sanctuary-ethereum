// SPDX-License-Identifier: MIT
pragma solidity 0.8.7; // Latestest version - 0.8.18

contract SimpleStorage {
    // Like Classes
    //  boolean , uint ,int ,address , bytes
    // bool hasFavouiteNumber = true;
    // uint64 num = 123;
    // int num2 = 45;
    // string text = "Hello World";
    // address myaddress = 0x4Bd173f33cC6Db62f95E2bDBaF6d5723c179a668;
    // bytes32 Bytes = "cat";

    uint256 public number;
    // People public person = People({rank: 1, name: "Parthib"});

    mapping(string => uint256) public nameToNum;

    struct People {
        uint256 rank;
        string name;
    }

    People[] public people;

    function store(uint256 _number) public virtual {
        number = _number;
        // retrieve() -> then gas will cost
    }

    // view , pure
    function retrieve() public view returns (uint256) {
        return number;
    }

    // calldata,memory,storage
    function addPerson(string memory _name, uint256 _rank) public {
        People memory newPerson = People({rank: _rank, name: _name});
        people.push(newPerson);
        nameToNum[_name] = _rank;
    }
}

// 0xf8e81D47203A594245E36C48e151709F0C19fBe8