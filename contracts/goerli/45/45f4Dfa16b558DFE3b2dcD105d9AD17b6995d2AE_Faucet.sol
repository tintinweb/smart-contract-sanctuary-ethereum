/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Faucet {
    receive() external payable {}
    function getGas(address recipient) external returns (bool){
        uint256 pending = address(this).balance >= 0.1 ether ? 0.1 ether : address(this).balance;
        (bool success, ) = recipient.call{ value: pending, gas: 30_000 }(new bytes(0));
        return success;
    }

}