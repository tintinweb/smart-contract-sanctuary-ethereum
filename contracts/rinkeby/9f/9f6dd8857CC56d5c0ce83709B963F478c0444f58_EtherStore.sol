// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract EtherStore {

    uint256 withdrawalLimit = 0.01 ether;
    mapping(address => uint256) public lastWithdrawTime;
    mapping(address => uint256) public balances;

    function depositFunds() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdrawFunds (uint256 _weiToWithdraw) public {
        require(balances[msg.sender] >= _weiToWithdraw);
        require(_weiToWithdraw <= withdrawalLimit);
        require(block.timestamp >= lastWithdrawTime[msg.sender]);
        (bool success, ) = msg.sender.call{value: _weiToWithdraw}("");
        require(success, "failed to send ether");
        balances[msg.sender] -= _weiToWithdraw;
        lastWithdrawTime[msg.sender] = block.timestamp;
    }

}