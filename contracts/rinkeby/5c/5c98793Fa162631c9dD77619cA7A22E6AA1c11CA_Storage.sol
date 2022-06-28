/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    uint256 number;
    uint8 smallNumber;

    function store(uint8 _smalNumber) public{
        smallNumber = _smalNumber;
    }

    function retrieveSmall() public view returns(uint8){
        return smallNumber;
    }

    function store(uint256 _number) public {
        number = _number;
    }

    function retrieve() public view returns (uint256){
        return number;
    }
}