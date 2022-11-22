/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    // uint256[] public anArray;
    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}

// // SPDX-License_Identifier: MIT
// pragma solidity 0.8.7; // first part of every solidity file. Need to specify version

// // the ^ before the version signifies any version including this one and above is ok for this contract
// // can also do >=0.8.7 <0.9.0

// // EVM
// // any smart contract that has an EVM, it is possible to deploy solidity code to
// // avalanche, Fantom, Polygon etc

// // composability - the ease at which contracts interact with one another
// // contract SimpleStorage{
// //     // uint - unsigned integer that is positive
// //     // int - positive or negative whole number
// //     // address is its own var type
// //     bool hasFavoriteNumber = true;
// //     uint256 favoriteNumber = 5; // if you don't specify, it is default uint256
// //     string favoriteNumberInText = "Five"; // good practice to be specific
// //     int256 favoriteInt = -5;
// //     address myAdress = 0x1066618d0973e44EfD2Fe5114fD18b64c64c6420AbB;
// //     bytes32 favoriteBytes = "cat";
// // } // think of contracts like classes in JS

// contract SimpleStorage {
//     uint256 favoriteNumber; // setting var without defining value sets to null value, which in solidity is 0.
//     // putting the public keyword here, then re complining and deploying,there is then a number with the name of this variable which when clicked gives you the number

//     mapping(string => uint256) public nameToFavoriteNumber;

//     // A mapping is a data structure where a key is "mapped" to a single value

//     function retrieve() public view returns (uint256) {
//         return favoriteNumber;
//     }

//     People public person = People({favoriteNumber: 2, name: "James"}); // like using a constructor for an obj
//     // in the getter UI, the uint256 is asking for the index of the person you want.
//     struct People {
//         uint256 favoriteNumber;
//         string name;
//     }
//     // this is like creating a type in typescript defining for an obj?

//     // uint256[] public favoriteNumbersList; also valid
//     People[] public people;

//     // if you put a number in the brackets it indicates the maximum length that the array is allowed to be ex: People[3] can only have 3 people in it

//     function store(uint256 _favoriteNumber) public virtual {
//         favoriteNumber = _favoriteNumber;
//     }

//     function addPerson(string memory _name, uint256 _favoriteNumber) public {
//         People memory newPerson = People({
//             favoriteNumber: _favoriteNumber,
//             name: _name
//         });
//         people.push(newPerson);
//         nameToFavoriteNumber[_name] = _favoriteNumber;
//         // (People is the struct(type) newPerson is the name of the var in this addPerson scope.
//         // or
//         // people.push(People(_favoriteNumber, _name));
//         // pushing a new People(person object) into the people array
//     }
// }

// // Visibility Specifiers:
// // Public, private, external, internal
// // public - visibile internally and externally - anyone who interacts with this contract. Creates a getter function for these variables.
// // private- only this contract can call this function.
// // external - only visible externally
// // internal - only this contract and children contracts

// // bits - smallest form of data either 0 or 1
// // byte - 8 bits

// // 0xd9145CCE52D386f254917e481eB44e9943F39138

// // view and pure functions don't have to spend gas when called alone
// // view and pure functions disallow modification of state.
// // pure function also disallow reading blockchain state

// // places to store data in solidity

// // EVM can access and store information in six places:
// // stack, memory, storage, calldata, code , logs

// //calldata and memory are stored temporarily. The difference is that calldata cannot be reassigned while memory can

// // calldata: temp vars that can't be modified.
// // memory: temp vars which can be modified;
// // storage: permanent variables which can be modified.

// // we can only declare a variable to be stored in one of these places ^
// // arrays, structs, and mappings are considered to be special types in solidity. These vars we must declare where and how they should be saved, for UINT, however, we don't need to declare this information.
// // strings are secretly arrays of bytes so that's why we need to specify it.