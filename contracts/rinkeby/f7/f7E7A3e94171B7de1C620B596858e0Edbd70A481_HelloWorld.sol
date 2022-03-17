/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.0;

contract HelloWorld {
    /*
        This is a simple contract built for a task
        in block games program 
    */

    uint256 specialNumber;

    function sayHello() pure public returns(string memory){
        return "Hello from my smart contract";
    }


    //@dev this method is used to set a value to the special number
    function setSpecialNumber(uint256 _newValue) public {
        specialNumber = _newValue;
    }

    //@dev this method is used to add a specified value to the special number
    function addToSpecialNumber(uint256 _value) public {
        specialNumber += _value;
    }

    //@dev this method is used to multiply a special number by a specific amount
    function multiplySpecialNumber(uint256 _value) public {
        specialNumber *= _value;
    }

    //@dev this is used to view the special number
    function viewSepcialNumber() public view returns(uint256){
        return specialNumber;
    }
}