/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

/**
 *Submitted for verification at FtmScan.com on 2022-03-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract FantomAnyCallContract{
    event NewMsg(string msg);


        //this function is supposed to be executed by mpc address and anycall contract
    function step2_createMsg(string calldata _msg) external {
        emit NewMsg(_msg);
    }

}