/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;


contract HomeContract {

    function payBackLess(uint num) external payable {
        require(num != 9, "We don't like 9");
        
        if(num % 2 == 0) {
            uint256 halfRefundEth = msg.value / 2;
            payable(msg.sender).transfer(halfRefundEth);
        } else {
            payable(msg.sender).transfer(msg.value);
        }
    }
}