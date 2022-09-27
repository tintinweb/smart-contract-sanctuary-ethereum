/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract Comet {
    int _reserveBalance = 110;
    
    function getReserves() public view returns (int) {
        return _reserveBalance;
    }
    
    function setReserveData(int _resBal) public{
        _reserveBalance = _resBal;
    }
}