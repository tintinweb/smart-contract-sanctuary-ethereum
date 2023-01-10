/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract MyHomework {
    function paybackNumber(uint256 num) external payable{
        
        require(num != 9, "we dont like 9");
        if (num % 2 == 0) {
           uint ethRefund = msg.value / 2;
            payable(msg.sender).transfer(ethRefund);
        } else {
            payable(msg.sender).transfer(msg.value);
        }
        
    }



  

}