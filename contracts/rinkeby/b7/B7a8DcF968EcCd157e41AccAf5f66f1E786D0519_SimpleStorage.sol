//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
  // automatically initialized with value of zero
  // visibility automatically set to private
  // reading data doesn't modifiy chain, so its not a transaction
  uint256 favoriteNumber;
  //   how to use a struct
  People public person = People({favoriteNumber: 21, name: "Daniel"});

  People[] public persons;

  // struct adds OOP feel
  struct People {
    uint256 favoriteNumber;
    string name;
  }

  mapping(string => uint256) public nameToFavoriteNumber;

  // this modifies data, so each time its called, it costs a bit of eth & gas to execute
  function store(uint256 _favoriteNumber) public virtual {
    //   more stuff you do, the more expensive the transaction excluding
    favoriteNumber = _favoriteNumber;
    favoriteNumber = favoriteNumber + 1;
  }

  function getNum() public view returns (uint256) {
    return favoriteNumber;
  }

  // calldata, memory are used to define a variable existing for a short moment
  // use calldata if param isn't reassigned else use memory
  // storage is permanent
  // can only use memory/calldata on mappings, arrays or strings(array of bytes)
  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    persons.push(People(_favoriteNumber, _name));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
}