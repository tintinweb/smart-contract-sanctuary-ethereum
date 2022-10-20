/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// An requester that will return the Tesla Stock Price by calling a dxFeed airnode.
contract TestAutomate {
    address sender;

    function fillData() public {
        sender = msg.sender;
    }
}