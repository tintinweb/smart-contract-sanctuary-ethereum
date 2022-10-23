// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

// EVM is a standard to deploy smart contracts to Ethereum like blockchains
// Example: Avalanche, Fantom, Polygon

contract SimpleStorage {
  /******** Basic Data Types *******/
  // bool hasFavoriteNumber = false;
  // uint256 favoriteNumber = 5; // uint8 till uint256. uint256 is by default. Also we can set by the step of 8
  // string favoriteNumberInText = "Five"; // string are secretly bytes object but only for text
  // int256 favoriteInt = -5;
  // address myAddress = 0x2fC6cFa3178606255DE42358541C32aFD4DBF7F4;
  // bytes32 favoriteBytes = "cat";
  // here string would automatically converted to bytes object. Usually byte could look like 0x373sgagsya
  // bytes starts with minimum of 2 and could be changed by the step of 1 i.e. bytes3, bytes4... max bytes32

  // Every variable in Solidity is initialized by initial value. For uint it would be 0
  // default visibility of the variable is private
  // https://docs.soliditylang.org/en/latest/contracts.html#visibility-and-getters
  uint256 public favoriteNumber; // Global Scope

  function store(uint256 _favoriteNumber) public virtual {
    // need to specify virtual because in 3_ExtraStorage we need to override this function
    favoriteNumber = _favoriteNumber;
  }

  /* 
        Pure, View functions and Gas:
        - view and pure functions when called alone, don't spend gas
        - when called instead of transaction there would be a call. But execution cost would be mentioned.
        - Execution cost only incur "If a gas calling function call a view or fure function. Only then will it cost Gas"
        - Example from this contract if store function calls retrieve, it will incur the gas price.
    */

  // view and pure functions disallow modification of state
  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  // pure functions additionally disallow you to read from blockchain state
  function add() public pure returns (uint256) {
    return (1 + 1);
  }

  /********  Structs and Arrays   *******/
  // structs are used to define a new data type
  // by default in object the indexes are applied 0: favoriteNumber and 1: name
  struct People {
    uint256 favoriteNumber;
    string name;
  }

  People public person = People({favoriteNumber: 2, name: "Bilal"});

  // no size in array literals meaning dynamic array
  // uint256[] public favoriteNumbersList;
  People[] public people;

  /*
        6 Places you can store and access data:
            - calldata
            - memory
            - storage
            - code
            - logs
            - stack

        However variables can only be declared as:
            - memory: temporary location after execution data would be gone. Variable can be modified in this space.
            - calldata: like memory its a temporary location. But variable can't be modified
            - storage: permanent storage and data is accessible afterwards. favoriteNumber and persons are example of it
    */

  /*
        Mapping: Mapping is a data structure where key is "mapped" to a single value example from other language: dictionary
        Retrieval is really easy
    */
  mapping(string => uint256) public nameToFavoriteNumber; // by default all string values has been initialized to null value

  // Why memory is specified for string and not for uint256?
  // Data location can only be specified for array, struct or mapping types. These are special types.
  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    // people.push(People(_favoriteNumber, _name)); 1 way of doing it
    People memory newPerson = People({
      name: _name,
      favoriteNumber: _favoriteNumber
    });
    people.push(newPerson);
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
}