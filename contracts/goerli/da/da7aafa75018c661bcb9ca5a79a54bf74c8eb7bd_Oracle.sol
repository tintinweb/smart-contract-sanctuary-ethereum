/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

contract Oracle { 
    uint8 private number;
    uint8 private number2;
    bool private result;
    mapping (address => bool) private roleCall;

    modifier onlyRole(address _caller){
        require (roleCall[_caller] == true, "5x00");
        _;
    }

    constructor (){
        roleCall[msg.sender] = true;
    }

    function setRole(address _caller1, address _caller2, address _caller3, address _caller4, address _caller5)external onlyRole(msg.sender){
        roleCall[_caller1] = true;
        roleCall[_caller2] = true;
        roleCall[_caller3] = true;
        roleCall[_caller4] = true;
        roleCall[_caller5] = true;
    }

    function _shipSunk()external onlyRole(msg.sender) returns(bool){
        unchecked {
            number = number + 253;
        }
        uint check = number % 2;
        if( check == 0){
            unchecked {
                number2 = number2 + 253;
            }
            uint check2 = number2 % 2;
            if( check2 == 0){
                result = true;
            }
            else {
                result = false;
            } 
        }
        else {
            result = false;
        }     
        return result;
    }































}