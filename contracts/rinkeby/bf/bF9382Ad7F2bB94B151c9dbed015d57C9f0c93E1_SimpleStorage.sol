//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    //boolean, unit, int, address, bytes
    uint256 public favoriteNumber; // default value is 0
    //Create a simple list
    //People public person = People({favoriteNumber: 2, name: "Ahmed"});
    //The Parenthases is to indicate we are getting the varialbles from the struct below.

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // uint256[] public favoriteNumberList;
    // To create an array
    // If we need to specify the size of the array we add the no. in the [] eg. [3] means it stores 3 lists.
    //It is empty [] then means it is unspecified size and can take any size.
    People[] public people; // we have a blue button in the deploy section bec. it is public and an int which makes it visible.

    //0: 2, {atrocl, 1: 7, Jon - example

    //  Use virtual to allow this function to be orverridable by any other function. eg. in ExtraStorage.sol.
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view, pure function is to read. no update on blockchain and no gas fee. If we used the retrieve function in this example
    // inside the store function then it will cost gas.
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    mapping(string => uint256) public nameToFaboriteNumber;

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFaboriteNumber[_name] = _favoriteNumber;
    }

    //   function add() public pure returns (uint256){
    //   }
}

//0xd9145CCE52D386f254917e481eB44e9943F39138