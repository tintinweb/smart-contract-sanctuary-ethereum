/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

//SPDX-License-Identifier: MIT

pragma solidity = 0.7;

contract GoFundMe {

// variables:
// - int, uint, int8, int16, int256, bool, byte, address

// function:
// - function foo(<param>) <visibily> <modifier> returns(<param>) { }
// visibily:
// - internal: Only invoked from inside the contract
// - external: Only invoked from outside the contract (3rd party)
// - private: Only invoked by other functions
// - public: invoked from anywhere!

// modifier:
// - pure: doesnt change any state (2+2)
// - view: only reads data from contract (getter method)
// - payable: allows transactions in the contract ( .transfer)

// - modifier onlyMe {
//     // run sometin
//     require()
//     _;
// }

// function foo() payable external onlyMe returns (int) {
//     ...
// }

    address constant Bob = 0x0986a33d12E4194286dF9DB4A203873197c22913; //Bob
    uint constant minEth = 50000000000000000; //0.05E

    modifier onlyBob {
        require(msg.sender == Bob, "This is only for Bob...");
        _;
    }

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    function deposit() external payable { 
        require(msg.sender != Bob, "Pls Bob...");
        require(msg.value >= minEth, "Send more ETH, pls...");
    }

    function withdrawl() external payable onlyBob {
        msg.sender.transfer(address(this).balance);
    }
}