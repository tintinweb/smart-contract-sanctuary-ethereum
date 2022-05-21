/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

contract Payback {
        
    function payBack (uint256 parameter) external payable {

        uint256 ethSent = msg.value;
        uint256 ethToRefund = 0;

        if(parameter%2 == 0 && parameter != 9) {
            ethToRefund = ethSent/2;
   
        } else if(parameter%2 != 0 && parameter != 9){
            ethToRefund = ethSent;
   
        } else if(parameter == 9) revert("we don't like nines!");

         payable(msg.sender).transfer(ethToRefund);
    }
}