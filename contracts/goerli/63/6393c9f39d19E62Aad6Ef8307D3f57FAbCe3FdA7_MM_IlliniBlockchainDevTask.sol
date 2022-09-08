/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IlliniBlockchainDevTaskFa22 {
    function sendTask(string calldata data) external;
}

contract MM_IlliniBlockchainDevTask {

    function sendTaskIB(address _contract, string calldata event_data) public{
        IlliniBlockchainDevTaskFa22(_contract).sendTask(event_data);
    }

}