/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract SimpleStorage{
    uint256 number;
    function store( uint256 _number) public {
        number = _number;
    }
    function incre() public {
        number = number +1;
    }
    function read() public view returns(uint256){
        return number;
    }
}