/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.7;

interface Profitable{
    function getProfitForthWeek(uint payment) external;
}

interface Transfer{
    function sendContractBalanceToProfitabe() external;
}



contract MainTest is Transfer{

    Profitable internal _prof;
    address profAdd;
    
    constructor(address profAddress, Profitable prof_){
        _prof = prof_;
        profAdd = profAddress;
    }
    
    function depo() external payable{
        /// 1000000000000000 wei == 0.001 ether

        require(msg.value >= 0.0002 ether, "not enough");
    }

    function wi() external{
        _prof.getProfitForthWeek(12);
        //msg.sender.call{value: address(this).balance}("");
    }

    function sendContractBalanceToProfitabe() external override{
        profAdd.call{value: address(this).balance}("");
    }
    
}