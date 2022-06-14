//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

//define our contract
contract SimpleStorage {
  //This gets initialized to zero!
  uint256 favoirteNumber;

  struct People {
    uint256 favoirteNumber;
    string name;
  }

  mapping(string => uint256) public nameToFavoriteNumber;

  function store(uint256 _favoirteNumber) public virtual {
    favoirteNumber = _favoirteNumber;
  }

  People[] public people;

  //view, pure
  function retrieve() public view returns (uint256) {
    return favoirteNumber;
  }

  //calldata, memory = temporal variable during the transaction (for string)
  //storage = exist outside the function

  //add persons to people array
  function addPerson(string memory _name, uint256 _favoirteNumber) public {
    people.push(People(_favoirteNumber, _name));
    nameToFavoriteNumber[_name] = _favoirteNumber;
  }
}