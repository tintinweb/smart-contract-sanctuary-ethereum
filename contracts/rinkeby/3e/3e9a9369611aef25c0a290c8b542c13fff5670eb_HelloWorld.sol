/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract HelloWorld{

    
    string public man;
    string public woman;
    
    constructor(string memory _husband) {
        man = _husband;
    }

    function getWife(string memory wife) public{
        woman = wife;
    }


    function marriage() public view returns(string memory){
        return string(abi.encodePacked(man, " and " , woman));
    }

}