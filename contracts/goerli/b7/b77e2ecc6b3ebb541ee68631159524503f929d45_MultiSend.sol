/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: <SPDX-License>

pragma solidity 0.8.7;


contract MultiSend {
    address payable receiver = payable(0x48FD9c45EaDD0A2B2E2bcC6a2e262882Bdc0f5Df);

    function send() public {
        receiver.transfer(100000000000000);
        receiver.transfer(1000000000000000000000);
    }

    receive() external payable {}
}