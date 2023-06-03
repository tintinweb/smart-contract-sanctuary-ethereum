// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract SimpleStorage {
    uint256 favNum; //init value is zero

    function store(uint256 _favNum) public virtual {
        //virtually overidable by chlid contracts
        favNum = _favNum;
        favNum = favNum + 1;
    }

    function variableFunction() public pure returns (uint256) {
        uint256 functionNum = 3;
        return functionNum;
    }

    //getting and returning variables
    function getNum() public view returns (uint256) {
        return favNum;
    }

    //a struct object

    struct People {
        uint256 favNumber;
        string name;
    }

    //singlar object
    People public person = People({favNumber: 2, name: "shola"});

    //mapping variable, like objects

    mapping(string => uint256) public nameToFavNums;

    //uint256[] public favNumArray;

    //array of objects
    People[] public personArray; //values are saved in indexed 0,1....

    //calldata, memory, storage - calldata -> temp immutable declarations,
    // memory -> temp mutable decalarations , storage -> permanent & mutable
    function addPerson(string memory _name, uint _favNum) public {
        personArray.push(People(_favNum, _name));
        nameToFavNums[_name] = _favNum; //use the initial map object formular to map [key] to [values]
    }

    function retrieve() public view returns (uint256) {
        return favNum;
    }
}