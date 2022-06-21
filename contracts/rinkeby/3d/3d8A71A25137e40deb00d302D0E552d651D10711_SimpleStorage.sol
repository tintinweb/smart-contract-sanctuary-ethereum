/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: MIT
// SPDX License Identifiers can be used to indicate relevant license information at any
// level, from package to the source code file level. Accurately identifying the license for
// open source software is important for license compliance.

// EVM: Ethereum Virtual Machine

// Declaring Solidity Version
// pragma solidity ^0.8.7; //To Use Solidity versions above 0.8.7 less than 0.9.0
// pragma solidity 0.8.7; //To use Solidity version 0.8.7 only
// pragma solidity >=0.8.7 <0.9.0; //To use Solidity versions betweee 2 versions
pragma solidity ^0.8.7;

contract SimpleStorage {
  //contract is like class in Java
  //Types in Solidity:
  // uint, boolean, int, address, bytes, string
  // number next to uint and int is bits, max - 256, min - 8
  // number next to bytes is no of bytes, max 32
  // bool hasFavoriteNumber = true;
  // uint256 favNum = 5;
  // string favStr = "Ayush";
  // int256 favInt = -12;
  // address myAddress = 0xaEB191Bc8253B7e3B67bEd30740005C5BE4a31FD;
  // bytes32 favBytes = "cat";
  // uint256 public favouriteNumber; //initialized  to zero; visibility initialized to private
  uint256 favouriteNumber;

  //Functions
  function store(uint256 _favouriteNumber) public virtual {
    //virtual makes function overrideable
    favouriteNumber = _favouriteNumber;
  }

  // NOTE: The more stuff you do higher the gas fee

  function retrieve() public view returns (uint256) {
    return favouriteNumber;
  }

  // types of funtions - view, pure
  // view functions just read something and make no change to the state of the blockchain
  // thus they dont cost any gas
  // pure functions dont read anything and make no change to the state of the blockchain
  // This also doesnt cost gas
  // NOTE: If a gas costing functuin calls a pure or view function, then they cost gas

  // Struct
  struct people {
    uint256 favouriteNumber;
    string name;
  }
  people public person = people({favouriteNumber: 2, name: "Ayush"});

  // Array
  people[] public humans; // Dynamic Array
  // Ecample of fixed array - people[3] public humans;
  uint256[] public favouriteNumbers;
  // Mappings
  mapping(string => uint256) public nameToFavouriteNumber;

  function addPerson(string memory _name, uint256 _favouriteNumber) public {
    // humans.push(people(_favouriteNumber, _name));
    // people memory newPerson = people({favouriteNumber: _favouriteNumber, name: _name});
    people memory newPerson = people(_favouriteNumber, _name); // This is less explicit hence upper way is better
    humans.push(newPerson);
    nameToFavouriteNumber[_name] = _favouriteNumber;
  }


}