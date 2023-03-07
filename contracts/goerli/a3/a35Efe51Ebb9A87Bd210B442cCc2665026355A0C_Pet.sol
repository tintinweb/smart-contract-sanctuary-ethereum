/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Pet {

    event PetURI(
        string value, // 宠物元数据
        uint256 id // 宠物编号
    );

    function setURI(
        string calldata newURI, // 宠物新的元数据
        uint256 id // 宠物编号
    ) public {
        emit PetURI(newURI, id); // 调用PetURI事件
    }
}