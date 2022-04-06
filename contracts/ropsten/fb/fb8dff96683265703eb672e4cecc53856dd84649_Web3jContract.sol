/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Web3jContract {

    string public value;

    constructor(){
       value = "Hello World!";
    }

    function getViewValue() public view returns(string memory){
        return value;
    }

    function setValue(string memory _value) public{
        value = _value;
    }
}