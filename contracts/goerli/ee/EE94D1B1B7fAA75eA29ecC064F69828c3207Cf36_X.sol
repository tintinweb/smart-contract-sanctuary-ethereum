//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/*
ABSTRACT CONTRACT

Abstract contract is one which contains atleast one function without any implementation.
Such a contract can be used as a base contract.
Generally an abstarct contract contains both implemented as well as abstract functions.
Derived contract will implement the abstract functions and use the existing functions as and when required.

*/


// regular contract

contract X {

    function y() public pure returns(string memory){
        return 'hello';
    }
}


// abstract (base) contract, we cannot deploy abstract contract

contract Z {

    //since function has no implementation, we should mark it as virtual as it will be override in derived contract
    function s() public pure virtual returns(uint) {
        return 3;
    }
}