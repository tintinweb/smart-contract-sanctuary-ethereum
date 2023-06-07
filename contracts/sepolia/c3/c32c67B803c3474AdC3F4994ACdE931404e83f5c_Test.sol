/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Test {

    error InvalidAddressError();
    error InvalidAddressWithParamError(address _addr);

    bool public result;
    bool public result2;
    bool public result3;
    
    function checkCustom() public returns (bool){
        address _input = address(0); 
        if (_input == address(0)) revert InvalidAddressError();
        result = true;
        return true;
    }

    function checkRequire() public returns (bool){
        address _input = address(1);
        result2 = true;
        require(_input == address(0), "############ Address must be non zero");
        return true;
    }

    function checkCustomParametrised() public returns (bool){
        address _input = address(4);
        result3 = true;
        if (_input != address(0)) revert InvalidAddressWithParamError(_input);
        return true;
    }
   
}