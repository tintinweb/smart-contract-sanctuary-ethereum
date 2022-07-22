// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    /* boolean ,uint,int,address , bytes,string
     uint256 explicitly defines we can store 8 bytes of unsigned data (Only Positive)
     Similarly int256 can be used and bytes32 has a maximum capacity of 4 bytes
     address stores the address of the account or some contract
     Default visibility is Internal */

    address myaccount = 0x298A78b65E641DE07E7b83bd9c203d7f48D1f0b1;
    uint256 num = 74;

    mapping(string => uint256) public nametonum;

    function change(uint256 number) public virtual {
        num = number;
    }

    /*Creating a function to return variable value as it in the backend.
     View and pure functions when called alone don't spend gas.
     View and pure functions disallow modification of state.
     Pure function additionally disallows you to read from blockchain state */
    function retrieve() public view returns (uint256) {
        return num;
    }

    /* Calling view and pure function is free unless we call the functions from 
    another normal function or from contract which costs gas*/

    //People public person = People({Number:7, name:"RAJ"});

    struct People {
        uint256 Number;
        string name;
    }

    //Creating an array of type people
    People[] public mankind;

    function addPerson(string memory _name, uint _number) public {
        People memory newPerson = People(_number, _name);
        //_number is passed first because People has taken Number first and name second
        mankind.push(newPerson);
        // We can pass value in this way too ; mankind.push(People(_number,_name));

        /* Calldata is temporary variable that cannot be modfied
        Memory is a temporary variable that can be modified
        Storage is permanent variable that can be modified. */

        nametonum[_name] = _number;
    }
}