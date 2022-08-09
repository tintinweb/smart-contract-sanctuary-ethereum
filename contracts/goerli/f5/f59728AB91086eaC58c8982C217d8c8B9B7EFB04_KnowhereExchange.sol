/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

// import {IErrorReport} from "./interfaces/IErrorReport.sol";

interface IErrorReport{

    error  permission(string err);

    error  currencyAlreadyExists(address token);

    error  royaltyAlreadyExists(string err);

    error  strategyAlreadyExists(string err);  

}

contract KnowhereExchange is IErrorReport{

    address public protocolFeeRecipient;

    // uint256 public auctionFee;

    // uint256 public fixedPriceFee;

    address owner;

    constructor(){
        owner = msg.sender;
    }

    function updateProtocolFeeRecipient(address recipient) external {
        if(owner != msg.sender) revert permission("Do not have permission to change the recipient");
        protocolFeeRecipient = recipient;
    }

}