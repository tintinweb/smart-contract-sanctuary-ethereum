/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

//SPDX-License-Identifier: MIT         
pragma solidity ^0.8.7;

interface IQuery {
    function _maxTxAmount() external returns(uint);
}

contract QueryContract {
    uint public maxTxIs;
    function getMaxtx(address _contract) external returns (uint){
        maxTxIs = IQuery(_contract)._maxTxAmount();
        return IQuery(_contract)._maxTxAmount(); 
    }   
}