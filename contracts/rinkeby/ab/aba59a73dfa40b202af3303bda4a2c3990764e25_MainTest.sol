/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.7;

interface Profitable{
    function getProfitFirstWeek(uint payment) external;
    function getProfitSecondWeek(uint payment) external;
    function getProfitThirdWeek(uint payment) external;
    function getProfitForthWeek(uint payment, uint balace_) external payable;
}


contract MainTest{

    Profitable internal _prof;

    constructor(Profitable prof_){
        _prof = prof_;
    }
    
    function depo() external payable{
        require(msg.value >= 0.002 ether, "not enough");
        _prof.getProfitForthWeek(0, address(this).balance);
    }

    function wi() external{
        msg.sender.call{value: address(this).balance}("");
    }
    
}