/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

/* tokeninsight.com
                                                                                       
     ,--.         ,--.                  ,--.               ,--.       ,--.       ,--.   
   ,-'  '-. ,---. |  |,-. ,---. ,--,--, |  |,--,--,  ,---. `--' ,---. |  ,---. ,-'  '-. 
   '-.  .-'| .-. ||     /| .-. :|      \|  ||      \(  .-' ,--.| .-. ||  .-.  |'-.  .-' 
     |  |  ' '-' '|  \  \\   --.|  ||  ||  ||  ||  |.-'  `)|  |' '-' '|  | |  |  |  |   
     `--'   `---' `--'`--'`----'`--''--'`--'`--''--'`----' `--'.`-  / `--' `--'  `--'   
                                                               `---'     
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Simplified IERC20 interface containing only the required functions for this contract
interface IERC20 {
    function transfer(address recipient, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
}

contract BatchTransfer {
    // Batch transfer Ether
    function batchTransferEther(address payable[] calldata recipients, uint256[] calldata amounts) external payable {
        require(recipients.length == amounts.length, "Recipients and amounts arrays must have the same length");

        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i].transfer(amounts[i]);
        }

        uint256 remainingBalance = address(this).balance;
        if (remainingBalance > 0) {
            payable(msg.sender).transfer(remainingBalance);
        }
    }

    // Batch transfer ERC20 tokens
    function batchTransferToken(IERC20 token, address[] calldata recipients, uint256[] calldata amounts) external {
        require(recipients.length == amounts.length, "Recipients and amounts arrays must have the same length");

        uint256 totalTokens = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            totalTokens += amounts[i];
        }

        token.transferFrom(msg.sender, address(this), totalTokens);

        for (uint256 i = 0; i < recipients.length; i++) {
            token.transfer(recipients[i], amounts[i]);
        }
    }

    function batchTransferTokenSimple(IERC20 token, address[] calldata recipients, uint256[] calldata amounts)
        external
    {
        require(recipients.length == amounts.length, "Recipients and amounts arrays must have the same length");
        for (uint256 i = 0; i < recipients.length; i++) {
            token.transferFrom(msg.sender, recipients[i], amounts[i]);
        }
    }
}