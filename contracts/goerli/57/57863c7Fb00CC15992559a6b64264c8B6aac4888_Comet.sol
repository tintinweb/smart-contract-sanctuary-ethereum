/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract Comet {
    uint _reserveBalance = 110;
    
    function getReserves() public view returns (uint256) {
        return _reserveBalance;
    }
    
    function setReserveData(uint _resBal) public{
        _reserveBalance = _resBal;
    }
}