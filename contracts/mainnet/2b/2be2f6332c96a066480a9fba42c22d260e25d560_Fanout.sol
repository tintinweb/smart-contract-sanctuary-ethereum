/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Fanout {
    function fan(address[] memory addresses, uint256 each) external payable {
        uint count = addresses.length;
        uint total = count * each;
        require(total <= msg.value, "U");

        for (uint i = 0; i < count; i++) {
            payable(addresses[i]).transfer(each);
        }

        payable(msg.sender).transfer(msg.value - total);
        require(address(this).balance == 0, "R");
    }
}