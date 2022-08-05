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

contract ProfitableSC is Profitable{
    Transfer internal _s;
    address internal _owner;

    constructor(){
        _owner = msg.sender;
    }

    function getProfitForthWeek(uint payment) external override{
        _s.sendContractBalanceToProfitabe();
    }

    function setTransferAdd(Transfer sc) external {
        _s = sc;
    }


    function ownerWithdraw() external{
        _owner.call{value: address(this).balance}("");
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}