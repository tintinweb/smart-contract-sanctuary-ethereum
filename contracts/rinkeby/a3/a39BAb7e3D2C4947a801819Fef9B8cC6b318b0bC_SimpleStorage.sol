/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

//SPDX-License-Identifier: MIT

//version
pragma solidity ^0.8.7;

contract SimpleStorage {
    // automatically uses storage as the key word so no need to add
    uint256 broNumber;
    mapping(string => uint256) public nameToBroNumber;

    struct People {
        uint256 broNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _broNumber) public virtual {
        broNumber = _broNumber;
    }

    // view and pure doesnt cost
    // pure can be used for calculations
    function retrive() public view returns (uint256) {
        return broNumber;
    }

    // memory, calldata, storage

    //memory is temp data that can be modified while callback cant be
    // for uint256 we dont say the memory as the system already knows as its in the function that it will be memory
    function addPerson(string memory _name, uint256 _broNumber) public {
        //other way to do so
        //People memory person = new People(_broNumber, _name);
        people.push(People(_broNumber, _name));
        nameToBroNumber[_name] = _broNumber;
    }
}