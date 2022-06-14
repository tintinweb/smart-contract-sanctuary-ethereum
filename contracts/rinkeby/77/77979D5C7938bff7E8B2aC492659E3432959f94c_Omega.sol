//SPDX-License-Identifier:GPL-3.0
pragma solidity ^0.8.10;
contract Omega {

    string public name = "Lily";
    function setName(string  memory _name) public {
        name = _name;
    }
    function getName() public view returns(string memory){
        return name;
    }
}