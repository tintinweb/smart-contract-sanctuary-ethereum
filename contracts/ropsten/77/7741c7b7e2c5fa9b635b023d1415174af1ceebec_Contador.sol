/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

contract Contador{

    uint256 count;

    constructor(uint256 _count){
        count = _count;

    }

    function setCount(uint256 _count)public{
        count = _count;

    }
    function aumentarCount() public{
        count += 3;
    }

    function getCount() public view returns(uint256){
        return count;

    }
    function getNumber() public pure returns(uint256){
        return 33;
    }
}