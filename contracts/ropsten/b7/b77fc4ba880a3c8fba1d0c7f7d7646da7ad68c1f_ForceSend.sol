/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.4.23;

// selfdestruct: 该指令绕过任何检查。
// 当合约执行自毁操作时，合约账户上剩余的以太币会发送给指定的目标
// 向合约发送以太币需要实现回退功能，但可以通过调用 selfdestruct 包含以太币的合约上的指令来强制发送以太币。
// 由于可以预先计算合约地址，因此可以在部署合约之前将以太币发送到某个地址
contract ForceSend {
    
    string public name;

    constructor () public {
        name = 'ForceSend';
    }

    function destruct(address target) external payable {
        require(msg.value > 0);
        selfdestruct(target);
    }

    function() public payable {
        
    }

}