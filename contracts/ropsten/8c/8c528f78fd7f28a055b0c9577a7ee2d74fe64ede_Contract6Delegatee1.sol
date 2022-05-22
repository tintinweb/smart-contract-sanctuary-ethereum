/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.4.23;

// 关于 delegatecall 指令要知道的是调用是在调用者的上下文中执行的。
// 因此 delegatee 访问 delegator 的 owner 存储变量和 msg.sender。
contract Contract6Delegatee1 {

    string public name;

    constructor() public {
        name = 'Contract6Delegatee1';
    }

    function getMsgSender() external payable returns(address) {
        return msg.sender;
    }
    
    /* Fallback function, don't accept any ETH */
    function() public payable {
        revert("Contract6Delegatee1 does not accept payments");
    }

}