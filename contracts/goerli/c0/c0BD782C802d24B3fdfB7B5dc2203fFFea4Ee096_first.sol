/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7; // current version is 0.8.12

// pragma solidity >=0.8.7 <0.9.0    Any version is fine between 0.8.7 to 0.9.0

contract first {
    bool a = true; //can be true or false
    uint256 b = 5; //only positive integers (lowest can be define upto uint8)
    int c = -3; //All integers
    string str = "kanak424";
    address add = 0xD938D3d88c50eAf089e49A35cdD492c257951DF9; // can be address of any account or anything
    uint256 public number; // set default value to 0

    function assign(uint256 _number) public virtual {
        number = _number;
        number = number * 8;
    }

    // view only read variable in the blockchain and doesn't perform any operation. For ex: number=number+2 cannot be performed by view function
    function retrive() public view returns (uint256) {
        return number;
    }

    // pure function doesn't even read variable from blockchain its just do some number operation not on variable nut on constant number

    // view and pure function doesn't use any gas fee
    // gas is only used when there is change in blockchain

    //structures

    struct people {
        uint num;
        string name;
    }

    // people public person=people({num:45,name:"kanak"});
    // people public person2=people({num:5,name:"yash"});

    //arrays

    people[] public person;

    //memory : temporary modifiable variable
    //calldata : temporary non-modifiable variable
    //storage : permenant modifiable variable

    function addperson(uint256 _num, string memory _name) public {
        person.push(people(_num, _name));
        name_to_num[_name] = _num;
    }

    //maping is used for getting its number from name or anything.
    mapping(string => uint256) public name_to_num;
}

// public- can be seen by anybody (getter function:to display the value stored in variable)
// private - can only be operated by current contract
// external - can be called by other contracts too
// internal- can be called by current and its children contract