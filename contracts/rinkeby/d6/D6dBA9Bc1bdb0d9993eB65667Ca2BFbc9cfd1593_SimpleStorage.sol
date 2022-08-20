// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favrioteUint256 = 5;
    uint256 public favrioteNumber; // this will initialized to 0!, default visibility Internal thats why not showing
    bool favrioteBool = true;
    string favriouteString = "String";
    int256 favrioteInt256 = -5;
    address favriouteAddress = 0x0b200d6239A95338D41E7a7711F8d9310e41Bfb4;
    bytes32 favrioteByte32 = "cat"; // Cat is a string which will be converted to bytes32, bytes28

    struct People {
        uint256 favrioteNumber;
        string name;
    }

    //People public person = People({ favrioteNumber: 55, name: "patrik"});
    People[] public people; // defining dynamic Array
    mapping(string => uint256) public nameToFavriteNumber;

    function store(uint256 _favoriteNumber) public returns (uint256) {
        favrioteNumber = _favoriteNumber;
        return _favoriteNumber;
    }

    // memory to store value during execution of the function.
    // Store mean keep the value after execution of the function.
    //people.push(People({favrioteNumber: _favoriteNumber, name: _name}));
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavriteNumber[_name] = _favoriteNumber;
    }

    // view,pure are read of value form Blockchain, No any transaction.thats why blue colour
    // Pure is to make some math calculatio
    //function retrive(uint256 _favoriteNumber) public pure {
    //  _favoriteNumber + _favoriteNumber;
    //}
    function retrive() public view returns (uint256) {
        return favrioteNumber;
    }
}