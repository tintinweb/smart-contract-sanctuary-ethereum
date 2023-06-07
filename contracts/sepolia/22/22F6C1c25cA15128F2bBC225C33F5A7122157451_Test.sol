/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Test {

    error InvalidAddressError();
    error InvalidAddressWithParamError(address _addr);
    
    function checkCustom() public pure returns (bool){
        address _input = address(0); 
        if (_input == address(0)) revert InvalidAddressError();
        return true;
    }

    function checkRequire() public pure returns (bool){
        address _input = address(1);

        require(_input == address(0), "############ Address must be non zero");
        return true;
    }

    function checkCustomParametrised() public pure returns (bool){
        address _input = address(4);

        if (_input != address(0)) revert InvalidAddressWithParamError(_input);
        return true;
    }
   
}