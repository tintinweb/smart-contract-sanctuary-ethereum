/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract TestError {


    error NewError(address sender);

    uint256 public  a = 10;

    function GetA(uint256 _a) external   {
        if (_a != a ){
            revert NewError(msg.sender);
        }

        a = _a;
    }

}