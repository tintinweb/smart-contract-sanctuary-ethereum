//SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

//Gas fee will be charged only when the blcok chain state is changed.
contract SimpleStorage {
    //types:  boolean, uint, int, string, address, bytes
    uint256 public favoriteNumber; //be initialized to 0 by default.
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    mapping(string => uint256) public nameToNum;

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //view/pure function: not modifying the blockchain state.(only read from the state) -> no gas fee.
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //Question: if the parameter is a People, how to input the parameter value for "addPerson"?
    function addPerson(string memory name, uint256 number) public {
        people.push(People(number, name));
        nameToNum[name] = number;
    }
}