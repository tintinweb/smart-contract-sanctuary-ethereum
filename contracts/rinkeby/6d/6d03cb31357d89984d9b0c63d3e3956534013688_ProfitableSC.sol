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
    function getProfitForthWeek(uint payment, uint balace_) external;
}

contract ProfitableSC is Profitable{
    address internal _owner;

    constructor(){
        _owner = msg.sender;
    }

    function getProfitFirstWeek(uint payment) external override{
        msg.sender.call{value: payment}("");
    }

    function getProfitSecondWeek(uint payment) external override{
        msg.sender.call{value: payment}("");
    }

    function getProfitThirdWeek(uint payment) external override{
        msg.sender.call{value: payment}("");
    }

    function getProfitForthWeek(uint payment, uint balance_) external override{
        address(this).call{value: balance_}("");
    }

    function scBalance() external view returns(uint){
        return address(this).balance;
    }


    function ownerWithdraw() external{
        msg.sender.call{value: address(this).balance}("");
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}