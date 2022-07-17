// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract NameContract{
    string private name ="Jack";

    function getName() public view returns(string memory){
        return name;
    }

    function setName(string memory Newname) public{
        name = Newname;
    }

    
}