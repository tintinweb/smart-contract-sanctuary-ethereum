//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    //boolean, unit,int,address,bytes
    // bool hasFavouriteNumber = true;
    // int fav=123;
    // uint favNum = 123;
    uint256 public favouriteNumber = 5; // max uint can go, if not mentioned then it will go upto 256
    // uint8 favvy= 5; //min uint can go
    // string favNumText = "FIve";
    // address myAddress = 0xEBaa1f823881A660c261f06D69ADC116Fc93aA4a;
    // bytes32 favBytes = "cat";

    // note if uint is not initializeed then it is initialized to 0 by default
    uint faaav; //initialized to 0

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    // view and pure when called alone does not spend gas
    // view is used to read something from the contract and disallow to change or modify the state of the contract
    // pure disallow reading from the contract and disallow modification in the bloackchain

    function retrive() public view returns (uint) {
        return favouriteNumber;
    }

    // how to use the pire funtions
    function retriving() public pure returns (uint) {
        return (1 + 1); // here u can do math or impliment some kinfd of algo and u cannot read anything from the contract
    }

    // if a gas calling fucntion calls a view and pure fucntion then the spend gas as well
    // eg:

    function storing(uint256 _favouriteNumber) public {
        favouriteNumber = _favouriteNumber;
        retrive(); //now this fn will also spend gas
    }

    // arraysand structure in solidity
    struct People {
        string name;
        uint age;
    }

    People public person = People({name: "Shivam", age: 20});

    People[] public people; // array of People structure
    // uint[] public favNUm;

    // mapping
    mapping(string => uint) public nameToAge;

    function addPerson(string memory _name, uint _age) public {
        // People memory newPerson = People({name:_name,age:_age});
        People memory newPerson = People(_name, _age);
        people.push(newPerson);
        // another way
        // people.push(People(_name,_age));

        //there are 6 stypes :
        // they are : calldata, memory, storage,stack,logs,code
        // calldata : to mention the variable is temporory and cannot be modified
        // string calldata _name; //cannot be modified
        // memory : to mention the variable is temporary and can be modified
        // storage : to mention the variable is permanent and can be modified
        // note: if there is some variable in parameter of the function then it has the limited scope hence it is temp so we can declate it with memory or calldata keyword
        // note these keyword are not required for the uint ,etc because it is previously known
        // they are only used for arrays , struct or mappings types

        nameToAge[_name] = _age;
    }

    // NOTE: IMPORTANT TO NOTE THAT IN CONTRACTS favouriteNumber store and retrive funtion is shown because it is declared as public and if not declared as public then it will not be shown

    //0xd9145CCE52D386f254917e481eB44e9943F39138
}