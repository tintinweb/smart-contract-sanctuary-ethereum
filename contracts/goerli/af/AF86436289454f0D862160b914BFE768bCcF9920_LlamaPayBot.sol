/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

//SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

interface LlamaPay {
    function withdraw(address from, address to, uint216 amountPerSec) external;
}

contract LlamaPayBot {

    address public bot = 0xA43bC77e5362a81b3AB7acCD8B7812a981bdA478;
    address public llama = 0x7B3cCe19124aA3a4378768BF0EF6555709b51481;
    address public newLlama = 0x7B3cCe19124aA3a4378768BF0EF6555709b51481;
    uint public fee = 30000; // Covers bot gas cost for calling function

    event WithdrawScheduled(address owner, address llamaPay, address from, address to, uint216 amountPerSec, uint40 starts, uint40 frequency, bytes32 id);
    event WithdrawCancelled(address owner, address llamaPay, address from, address to, uint216 amountPerSec, uint40 starts, uint40 frequency, bytes32 id);
    event WithdrawExecuted(address owner, address llamaPay, address from, address to, uint216 amountPerSec, uint40 starts, uint40 frequency, bytes32 id);
    event WithdrawFailed(address owner, bytes data);
    event OwnerWithdrawFailed(address _owner);

    mapping(address => uint) public balances;
    mapping(bytes32 => address) public owners;

    function scheduleWithdraw(address _llamaPay, address _from, address _to, uint216 _amountPerSec, uint40 _starts, uint40 _frequency) external {
        bytes32 id = getWithdrawId(msg.sender, _llamaPay, _from, _to, _amountPerSec, _starts, _frequency);
        require(owners[id] == address(0), "event already has owner");
        owners[id] = msg.sender;
        emit WithdrawScheduled(msg.sender, _llamaPay, _from, _to, _amountPerSec, _starts, _frequency, id);
    }

    function cancelWithdraw(address _llamaPay, address _from, address _to, uint216 _amountPerSec, uint40 _starts, uint40 _frequency) external {
        bytes32 id = getWithdrawId(msg.sender, _llamaPay, _from, _to, _amountPerSec, _starts, _frequency);
        require(msg.sender == owners[id], "not owner of event");
        owners[id] = address(0);
        emit WithdrawCancelled(msg.sender,_llamaPay, _from, _to, _amountPerSec, _starts, _frequency, id);
    }

    function executeWithdraw(address _owner, address _llamaPay, address _from, address _to, uint216 _amountPerSec, uint40 _starts, uint40 _frequency, bool emitEvent) external {
        require(msg.sender == bot, "not bot");
        bytes32 id = getWithdrawId(_owner, _llamaPay, _from, _to, _amountPerSec, _starts, _frequency);
        if (_llamaPay != address(0) && _from != address(0) && _to != address(0) && _amountPerSec != 0) {
            LlamaPay(_llamaPay).withdraw(_from, _to, _amountPerSec);
        } 
        if (emitEvent) {
            emit WithdrawExecuted(_owner, _llamaPay, _from, _to, _amountPerSec, _starts, _frequency, id);
        }
    }

    function deposit() external payable {
        require(msg.sender != bot, "bot cannot deposit"); 
        balances[msg.sender] += msg.value;
    }

    function refund() external {
        uint toSend = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool sent,) = msg.sender.call{value: toSend}("");
        require(sent, "failed to send ether");
    }

    function executeOwnerWithdrawal(bytes[] calldata _calls, address _owner) external {
        require(msg.sender == bot, "not bot");
        uint i;
        uint len = _calls.length;
        uint startGas = gasleft();
        for (i = 0; i < len; ++i) {
            bytes calldata call = _calls[i];
            (bool success,) = address(this).delegatecall(call);
            if (!success) {
                emit WithdrawFailed(_owner, call);
            }
        }
        uint gasUsed = ((startGas - gasleft()) + 21000) + fee;
        uint totalSpent = gasUsed * tx.gasprice;
        balances[_owner] -= totalSpent;
        (bool sent, ) = bot.call{value: totalSpent}("");
        require(sent, "failed to send ether to bot");
    }

    function batchExecuteOwnerWithdrawals(bytes[] calldata _calls, address[] calldata _owners) external {
        require(msg.sender == bot, "not bot");
        uint i;
        uint len = _owners.length;
        for (i = 0; i < len; ++i) {
            (bool success,) = address(this).delegatecall(_calls[i]);
            if (!success) {
                emit OwnerWithdrawFailed(_owners[i]);
            }
        }
    }

    function changeBot(address _newBot) external {
        require(msg.sender == llama, "not llama");
        bot = _newBot;
    }

    function changeLlama(address _newLlama) external {
        require(msg.sender == llama, "not llama");
        newLlama = _newLlama;
    }

    function confirmNewLlama() external {
        require(msg.sender == newLlama, "not new llama");
        llama = newLlama;
    }

    function changeFee(uint _newFee) external {
        require(msg.sender == llama, "not llama");
        fee = _newFee;
    }

    function getWithdrawId(address _owner, address _llamaPay, address _from, address _to, uint216 _amountPerSec, uint40 _starts, uint40 _frequency) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_owner, _llamaPay, _from, _to, _amountPerSec, _starts, _frequency));
    }

}