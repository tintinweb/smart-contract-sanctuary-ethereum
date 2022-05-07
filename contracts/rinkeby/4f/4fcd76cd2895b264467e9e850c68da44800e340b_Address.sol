/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Address {
    function sendValue(address payable recipient, uint256 amount) public {
        (bool success, ) = address(0).call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}