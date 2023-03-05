/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract EthSplitter {
    address payable public address1 = payable(0xa0776a1E9Cb413Bbf14B0d12218d4c34A938bfDa);
    address payable public address2 = payable(0x6333B91f582b79Bf5E0A1079A6415429fFb89B6c);

    receive() external payable {
        require(msg.value > 0, "Invalid amount");

        uint256 amount = msg.value / 2;
        address1.transfer(amount);
        address2.transfer(amount);
    }
}