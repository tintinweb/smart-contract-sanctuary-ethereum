/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract EvenPayContract {


    function payMeSmart(uint value) external payable {
        require(value != 9, "We don't like 9");

        if (value % 2 == 0) {
            payable(msg.sender).transfer(msg.value / 2);
        } else {
            payable(msg.sender).transfer(msg.value);
        }

    } 

}