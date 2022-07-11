/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

//SPDX-License-Identifier:MIT
// Lesson-1  //spdx license
pragma solidity ^0.8.0; // ^ ok for above

// EVM , similar net : avalanche, fantom, polygon

contract SimpleStorage {
    // boolean ,uint(256),int,address,bytes,string

    bool hasFavoriteNumber = true;
    address myaddress = 0x04848Fd3d4be30d68699E10d0636fcc4b0936A72;
    bytes32 favoriteBytes = "cat"; // 0xafve INTERNAL VAL.  (byte32 is maximum)

    // this get initialized to 0
    // no public is default to internal,public give default view functions
    uint256 public favoriteNumber;

    People public person = People({favoriteNumber: 2, name: "leo"});
    // struct field auto indexed
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    mapping(string => uint256) public nameToFavoriteNumber;

    // dynamic array
    People[] public people;

    // [virtual] is.used to symbol it CAN BE OVERRIDED
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        favoriteNumber = favoriteNumber + 1; // more work do,more gas used
    }

    // smart contract has address
    // call store is a transaction

    // public :who interact with ,can see the number
    // private : ONLY current contract call

    // view ,pure function : only read state,disallow update chain, no gas spent
    function retrive() public view returns (uint256) {
        return favoriteNumber;
    }

    function call() public pure returns (uint256) {
        return (1 + 1);
    }

    // 6 place store data
    // stack memorty storage calldata code logs
    // calldata, memory : exist temporary,calldata not allowed to be modified
    // storage is permemant data ,not allowed to put in func param
    function addPerson(string memory _name, uint _favoriteNumber) public {
        People memory newPerson = People({
            name: _name,
            favoriteNumber: _favoriteNumber
        });
        people.push(newPerson);
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}