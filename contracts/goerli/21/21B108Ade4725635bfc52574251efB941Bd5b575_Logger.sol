/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

contract Logger{
    event Logged(
        address sender,
        uint256 id,
        string status
    );

    function AddLog()public{
        emit Logged(msg.sender,1,"yes");
    }
}