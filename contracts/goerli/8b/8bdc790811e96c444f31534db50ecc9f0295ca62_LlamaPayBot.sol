//SPDX-License-Identifier: AGPL-3.0-only

import "./ReentrancyGuard.sol";

pragma solidity ^0.8.0;

interface LlamaPay {
    function withdraw(address from, address to, uint216 amountPerSec) external;
}

contract LlamaPayBot is ReentrancyGuard {

    address public bot = address(0);
    address public llama = address(0);

    event WithdrawScheduled(address indexed llamaPay, address indexed from, address indexed to, uint216 amountPerSec, uint40 starts, uint40 frequency);
    event WithdrawCancelled(address indexed llamaPay, address indexed from, address indexed to, uint216 amountPerSec);
    event ExecuteFailed(address indexed payer, bytes data);

    mapping(address => uint) public balances;
    mapping(bytes32 => address) public owners;

    function scheduleWithdraw(address _llamaPay, address _from, address _to, uint216 _amountPerSec, uint40 _starts, uint40 _frequency, address _owner) external {
        bytes32 id = getWithdrawId(_llamaPay, _from, _to, _amountPerSec, _frequency, _owner);
        require(owners[id] == address(0), "event already has owner");
        owners[id] = msg.sender;
        emit WithdrawScheduled(_llamaPay, _from, _to, _amountPerSec, _starts, _frequency);
    }

    function cancelWithdraw(address _llamaPay, address _from, address _to, uint216 _amountPerSec, uint40 _frequency, address _owner) external {
        bytes32 id = getWithdrawId(_llamaPay, _from, _to, _amountPerSec, _frequency, _owner);
        require(msg.sender == owners[id], "not owner of event");
        owners[id] = address(0);
        emit WithdrawCancelled(_llamaPay, _from, _to, _amountPerSec);
    }

    function executeWithdraw(address _llamaPay, address _from, address _to, uint216 _amountPerSec) external {
        require(msg.sender == bot, "not bot");
        LlamaPay(_llamaPay).withdraw(_from, _to, _amountPerSec);
    }

    function deposit() external payable nonReentrant {
        balances[msg.sender] += msg.value;
    }

    function refund() external payable {
        uint toSend = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool sent,) = msg.sender.call{value: toSend}("");
        require(sent, "failed to send ether");
    }

    function executeTransactions(bytes[][] calldata _calls, address[] calldata _owners) external {
        require(msg.sender == bot, "not bot");
        uint i;
        uint ownerLen = _owners.length;
        for (i = 0; i < ownerLen; ++i) {
            uint j;
            uint callLen = _calls[i].length;
            uint startGas = gasleft();
            address owner = _owners[i];
            for (j = 0; j < callLen; ++j) {
                bytes calldata call = _calls[i][j];
                (bool success,) = address(this).delegatecall(call);
                if (!success) {
                    emit ExecuteFailed(owner, call);
                }
            }
            uint gasUsed = (startGas - gasleft()) + 21000;
            uint totalSpent = gasUsed * tx.gasprice;
            balances[owner] -= totalSpent;
            (bool sent, ) = bot.call{value: totalSpent}("");
            require(sent, "failed to send ether to bot");
        }
    }

    function changeBot(address _newBot) external {
        require(msg.sender == llama, "not llama");
        bot = _newBot;
    }

    function getWithdrawId(address _llamaPay, address _from, address _to, uint216 _amountPerSec, uint40 _frequency, address _owner) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_llamaPay, _from, _to, _amountPerSec, _frequency, _owner));
    }

}