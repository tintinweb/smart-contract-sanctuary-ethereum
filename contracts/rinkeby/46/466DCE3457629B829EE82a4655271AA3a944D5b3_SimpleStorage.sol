// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract SimpleStorage {
  /********** 1.Basic Types: **********/
  // boolean, unit, int, address, bytes
  // bool hasFavoriteNumber = true;
  // uint256 favoriteNum; // Default value of integer is 0
  // uint256 favoriteNumber = 7;
  // string favoriteNumberInText = "Seven";
  // int256 favoriteInt = -7;
  // address myAddress = 0x630A676DEca0952791Ea3A6BB9751d2f06540ee1;
  // bytes32 favoriteBytes = "cat";

  /********** 2.Function: **********/
  uint256 favoriteNumber;

  // Modifiers are inheritable properties of contracts
  // may be overridden by derived contracts
  // but only if they are marked virtual
  function store(uint256 _favoriteNumber) public virtual {
    favoriteNumber = _favoriteNumber;
  }

  /********** View Function: **********/
  // Read state from the contract
  // It doesn't spend gas
  // It disallow modification of state
  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  /********** Pure Function: **********/
  // It alos disallow read state from the contract
  // It doesn't spend gas
  // It disallow modification of state
  function add() public pure returns (uint256) {
    return (2 + 2);
  }

  /********** 3.Arrays & Structs: **********/

  // Struct
  struct People {
    uint256 favoriteNumber;
    string name;
  }

  People public person = People({favoriteNumber: 2, name: "Hinesh"});

  // Array
  People[] public people;

  // Add person into array function
  function addPeople(string memory _name, uint256 _favoriteNumber) public {
    // Long Method
    // People memory addPerson = People({ favoriteNumber :_favoriteNumber, name :_name});
    // people.push(addPerson);

    // Short Method
    people.push(People(_favoriteNumber, _name));

    //Mapping :- set _favoriteNumber into _name key
    nameTofavouriteNumber[_name] = _favoriteNumber;
  }

  /********** 4.Data Location: **********/

  // Data location only be specified for array, struct, mapping types
  // calldata :- temorary variable that can't be modify
  // memory :-  temorary variable that can be modify
  // storage :- permenant variable that can be modify

  /********** 5.Mapping: **********/
  // mapping(keyType => valueType) 'visibility' 'variable';
  mapping(string => uint256) public nameTofavouriteNumber;
}

// Metamask address:- 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4