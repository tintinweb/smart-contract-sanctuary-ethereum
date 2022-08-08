// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Delegatecallable {
    address public deployedThis; // Address on which the contract was deployed

    constructor() {
        deployedThis = address(this);
    }


    function isDelegateCall() public view returns(bool){
        return address(this) == deployedThis;
    }
}