// SPDX-License-Identifier:MIT
pragma solidity ^0.8.9;

contract Storage{
    uint public count = 100;                        // Stored @ Slot 0 [ Size : 32 bytes ]
    address public owner = msg.sender;              // Slot 1 [ Size : 20 bytes ] *Slot 1 still having 12 bytes*
    bool public isTrue = true;                      // Slot 1 [ Size : 1 byte ] *Slot 1  still having 11 bytes*
    uint16 public u16 = 31;                         // Slot 1 [ Size : 2 byte ] *Slot 1 still having 9 bytes*
    string private password;                       // Slot 2 [ Size : 32 bytes ] 
    uint public constant someConst = 300;           // Constants don't use storage.
    bytes32[3] public data;                         // Slot 3,4 & 5 will be used to store each array element [ Size : 32*3 bytes ] 
    struct User{        
        uint id;
        bytes32 password;
    }

    /*
        Slot 6 [ Stores length & elements of array ] ( keccak256(6) where array elements are stored. )
        - Each struct element will take 2 slots. ( 1 for uint and 1 for bytes32 ) 
        - Slot where array elements are stored  : keccak256(6) + ( index * elementSize ) 
        - First element of array  @ keccak256(6)
        - Second element of array @ keccak256(6) + 2
        - Third element of array @ keccak256(6) + 4 and so on... 
    */

    User[] private users;                     

    /*
        Slot 7 [ Stores key|value pair of mapping ] 
        - Values are stored at the hash of the (key,slot)
        - Value for first key will be @ keccak256(1,7)
        - Value for second key will be @ keccak256(2,7) and so on...
    */      

    mapping(uint => User) private idToUser;

    constructor(string memory _password){
        password = _password;
    }

    function addUser(bytes32 _password) public{
        User memory user = User({
            id : users.length,
            password : _password
        });
        users.push(user);
        idToUser[user.id] = user;
    }

    function getArrayLocation(uint slot, uint index, uint elementSize) public pure returns (uint){
        return uint(keccak256(abi.encodePacked(slot))) + (index * elementSize);
    }

    function getMapLocation(uint slot, uint key) public pure returns (uint){
        return uint(keccak256(abi.encodePacked(key,slot)));
    }
}