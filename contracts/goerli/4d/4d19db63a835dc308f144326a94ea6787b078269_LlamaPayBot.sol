//SPDX-License-Identifier: AGPL-3.0-only

import "./BoringBatchable.sol";

pragma solidity ^0.8.0;

interface LlamaPay {
    function withdraw(address from, address to, uint216 amountPerSec) external;
}

contract LlamaPayBot is BoringBatchable {

    address public bot = 0x9632c0578650F9d0e2581D6034A866bAa016efAA;
    address public llama = 0x9632c0578650F9d0e2581D6034A866bAa016efAA;

    event WithdrawScheduled(address indexed llamaPay, address indexed from, address indexed to, uint216 amountPerSec, uint40 starts, uint40 frequency);
    event WithdrawCancelled(address indexed llamaPay, address indexed from, address indexed to, uint216 amountPerSec);
    event ExecuteFailed(address indexed payer, bytes data);

    mapping(address => uint) public balances;
    mapping(bytes32 => address) public owners;

    function scheduleWithdraw(address _llamaPay, address _from, address _to, uint216 _amountPerSec, uint40 _starts, uint40 _frequency) external {
        bytes32 id = getWithdrawId(_llamaPay, _from, _to, _amountPerSec, _frequency);
        require(owners[id] == address(0), "event already has owner");
        owners[id] = msg.sender;
        emit WithdrawScheduled(_llamaPay, _from, _to, _amountPerSec, _starts, _frequency);
    }

    function cancelWithdraw(address _llamaPay, address _from, address _to, uint216 _amountPerSec, uint40 _frequency) external {
        bytes32 id = getWithdrawId(_llamaPay, _from, _to, _amountPerSec, _frequency);
        require(msg.sender == owners[id], "not owner of event");
        owners[id] = address(0);
        emit WithdrawCancelled(_llamaPay, _from, _to, _amountPerSec);
    }

    function executeWithdraw(address _llamaPay, address _from, address _to, uint216 _amountPerSec) external {
        require(msg.sender == bot, "not bot");
        LlamaPay(_llamaPay).withdraw(_from, _to, _amountPerSec);
    }

    function deposit() external payable {
        require(msg.value > 0, "need to send ether");
        (bool sent,) = address(this).call{value: msg.value}("");
        require(sent, "failed to send ether");
        balances[msg.sender] += msg.value;
    }

    function refund() external payable {
        uint toSend = balances[msg.sender];
        balances[msg.sender] -= toSend;
        (bool sent,) = msg.sender.call{value: toSend}("");
        require(sent, "failed to send ether");
    }

    function executeTransactions(bytes[] calldata calls, address _owner) external {
        require(msg.sender == bot, "not bot");
        uint i;
        uint len = calls.length;
        uint startGas = gasleft();
        for (i = 0; i < len; ++i) {
            bytes calldata call = calls[i];
            (bool success,) = address(this).delegatecall(call);
            if (!success) {
                emit ExecuteFailed(_owner, call);
            }
        }
        uint gasUsed = (startGas - gasleft()) + 21000;
        uint totalSpent = gasUsed * tx.gasprice;
        balances[_owner] -= totalSpent;
        (bool sent, ) = bot.call{value: totalSpent}("");
        require(sent, "failed to send ether to bot");
    }

    function changeBot(address _newBot) external {
        require(msg.sender == llama, "not llama");
        bot = _newBot;
    }

    function getWithdrawId(address _llamaPay, address _from, address _to, uint216 _amountPerSec, uint40 _frequency) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_llamaPay, _from, _to, _amountPerSec, _frequency));
    }

}