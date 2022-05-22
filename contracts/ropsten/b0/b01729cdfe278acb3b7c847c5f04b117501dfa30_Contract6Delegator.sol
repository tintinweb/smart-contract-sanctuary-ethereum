/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.4.23;


interface ICoinFlipChallenge {
    function getMsgSender66() external payable returns(address);
}

// 关于 delegatecall 指令要知道的是调用是在调用者的上下文中执行的。
// 因此 delegatee 访问 delegator 的 owner 存储变量和 msg.sender。
// 如果内部调用因 gas 耗尽而失败，则 delegator 代码不会恢复。
contract Contract6Delegator {

    string public name;

    constructor() public {
        name = 'Contract6Delegator';
    }

    function delegateCall1(address contractAddress) external payable returns(bool) {
        // getMsgSender66 执行失败: 当前合约状态修改成功
        name = 'Contract6Delegator update by delegateCall1';
        address delegatee = address(contractAddress);
        bool status = delegatee.call.gas(100000)(bytes4(keccak256('getMsgSender66()')));
        return status;
    }
    
    function delegateCall2(address contractAddress) external payable returns(address) {
        // getMsgSender66 执行失败: 当前合约状态修改失败
        name = 'Contract6Delegator update by delegateCall2';
        ICoinFlipChallenge challenge = ICoinFlipChallenge(contractAddress);
        address _address = challenge.getMsgSender66();        
        return _address;
    }

}