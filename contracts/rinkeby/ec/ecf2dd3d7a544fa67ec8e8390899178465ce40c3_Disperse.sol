/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


//library Address {
//    function sendValue(address payable recipient, uint256 amount) public {
//        (bool success, ) = address(0).call{value: amount}("");
//        require(success, "Address: unable to send value, recipient may have reverted");
//    }
//}

library Address {
    function sendValue(address payable recipient, uint256 amount) external {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

contract Disperse {
    using Address for address payable;

    function disperseEth(address payable[] calldata list, uint256[] calldata values) external payable {
        require(list.length == values.length, "Length not match");

        uint256 total = msg.value;
        for (uint256 i = 0; i < list.length; i++) {
            list[i].sendValue(values[i]);
            total -= values[i];
        }

        payable(msg.sender).sendValue(total);
    }
}