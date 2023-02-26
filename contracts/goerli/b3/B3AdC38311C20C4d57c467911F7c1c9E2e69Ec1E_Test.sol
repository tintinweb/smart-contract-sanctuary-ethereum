/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Test {
    event Receive(string message, uint256 value);

    //If msg.data is empty fallback is executed
    fallback() external payable {
        emit Receive("Called from smartcontract", msg.value);
    }

    //If msg.data is given then receive is executed, if receive is not existed in this function then fallback would have executed
    receive() external payable {
        emit Receive("Called from smartcontract", msg.value);
    }

    /* Check smart contract balance */
    function checkSmartContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}