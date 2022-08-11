//SPDX-License-Identifier: MIT
//we have to write above line as it is
pragma solidity ^0.8.7; 
contract SimpleStorage {
    //boolean, uint ,int, address, bytes ,string
    bool hasFavoriteNumber = true;
    //uint favoriteNumber;in tis way  favoriteNumber hold default value which is in solidity is zero.

    uint favoriteNumber; //uint stores only positive value
   

    People[] public people;

    struct People {
        uint256 myNumber;
        string name;
    }
    mapping(string => uint256) public nameToNumber;

   

    function store1(uint256 favoriteNumber2) public virtual {
        favoriteNumber = favoriteNumber2;
    }
    function retrieve() public view returns (uint256) {
        return favoriteNumber + 1;
    }

    function addPerson(string memory myName, uint256 _myNumber) public {
        People memory newPerson = People({myNumber: _myNumber, name: myName});
        people.push(newPerson);
      
        nameToNumber[myName] = _myNumber;
    }
}