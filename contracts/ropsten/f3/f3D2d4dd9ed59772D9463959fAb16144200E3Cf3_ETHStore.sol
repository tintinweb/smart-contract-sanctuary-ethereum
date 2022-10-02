// SPDX-License-Identifier: GPL-2.0-or-later



pragma solidity 0.7.6;

contract ETHStore {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 withdrawWei) public {
        require(balances[msg.sender] >= withdrawWei, "balance not En");
        msg.sender.call{ value: withdrawWei };
        balances[msg.sender] -= withdrawWei;
    }

    function withdraw1(uint256 withdrawWei) public {
        require(balances[msg.sender] >= withdrawWei, "balance not En");
        msg.sender.call{ value: withdrawWei }("");
        balances[msg.sender] -= withdrawWei;
    }

    function collectEther() public {
        msg.sender.transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external {}
}