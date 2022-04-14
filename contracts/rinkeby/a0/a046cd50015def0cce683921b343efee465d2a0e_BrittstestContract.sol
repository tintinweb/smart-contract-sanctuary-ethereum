/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract BrittstestContract {
    uint number;

    function setNumber (uint _number) public{
        number = _number;
    }

    function getNumber () public view returns(uint) {
        return number;
    }
}