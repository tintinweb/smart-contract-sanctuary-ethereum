/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

contract Logger{
    event Logged(
        address sender
    );

    function AddLog()public{
        emit Logged(msg.sender);
    }
}