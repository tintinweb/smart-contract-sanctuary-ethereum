/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7; //solidity version

//This is how solidity identifies a contract
//EVM--> Ethereum virtual machine
//Avalanch,fantom, polygon --> we can also deploy it in these blockchain using solidity
contract SimpleStorage {
  // basic data types in solidity are:
  // boolean, uint, int, address, bytes, String, and more

  //EXAMPLES:
  bool hasFavNumber = true; //declaration and intialization of a variable
  int256 fno = 1;

  string favdigit = "123";
  int256 sam = -5;
  address a = 0x2D36416aBf64190e079E2FD00E6AcC6F6cd7a2F4;
  bytes32 favByte = "cat"; // it willl get converted. It can go like bytes8, bytes16.... but no more than 32

  //default value is 0
  //it is also a default function
  uint256 favNum; // uint can go uint8,uint16,uint32.... till uint256.

  // store(24);
  //declaring the function
  function store(uint256 _fav_) public virtual {
    favNum = _fav_;
  }

  //view and pure function when it called alone, dont spend gas
  //view functions don't allow any mofification of state, same as pure.
  function retrive() public view returns (uint256) {
    return favNum;
  }

  //pure functions don't allow the data to be read from blockchain
  //we can use pure function if something is going repetative and we can create a pure function
  function add() public pure returns (uint256) {
    return 1 + 1;
  }

  //blockchain state is only we changed by public function not from pure and view functions
  //calling of a view function is free until we are calling it from the function which costs gas

  //this is how to create new object of structure
  // People public people = People({
  //     favoriteNum:2,
  //     name: "Yash"
  // });

  // this is how to create the array in solidity
  // uint256[] public favList; // this is a dynamic array as we have not initilized size yet
  //uint256[5] public favlist2; // max size can be 5
  People[] public people;

  //Another data structure known as mapping like HashMaps which have keys
  //also we can think of it as a dictionary

  mapping(string => uint256) public nameTofavnumber; //in this every single name will have a specific number or the string is mapped to uint256 (in this case)

  //this is how to declare structure in solidity
  struct People {
    uint256 favoriteNum;
    string name;
  }

  function addPerson(string memory _name, uint256 _favNumber) public {
    // people.push(People(_favNumber,_name));

    People memory newPeople = People(_favNumber, _name);

    people.push(newPeople);

    //people.push(People(_favNumber,_name));

    nameTofavnumber[_name] = _favNumber;
  }

  //EVm can access and store memory in six places
  // 1.Stack
  // 2.Memory(*)
  // 3.Storage(*)
  // 4.Calldata(*)
  // 5.Code
  // 6.Logs

  //calldata and memory mean that the variable only gonna exist temporarly or only in the function
  //by default memory is storage
  //calldata cannot be modified
  //storage are permanent variable that can be modified
  //struts mapping and array needed the memory or call data function

  //0xd9145CCE52D386f254917e481eB44e9943F39138
}