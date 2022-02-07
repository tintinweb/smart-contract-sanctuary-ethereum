/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;

contract HelloWorld{
    string name;

    function setName(string memory _name) public {
        name = _name;
    }
    function getName() public view returns(string memory nm){
        return name;
    }
}