// SPDX-License-Identifier: GPL-2.0-or-later



pragma solidity 0.7.0;

contract ETHStore {
    mapping(address => uint256) public balances;

    event Deposit(address indexed usder, uint256 amount);

    function deposit() public payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdrawFunds(uint256 _weiToWithdraw) public {
        require(balances[msg.sender] >= _weiToWithdraw);
        (bool send, ) = msg.sender.call{ value: _weiToWithdraw }("");
        require(send, "send failed");
        balances[msg.sender] -= _weiToWithdraw;
    }

    function collectEther() public {
        msg.sender.transfer(address(this).balance);
    }

    receive() external payable {
        if (msg.value > 0) {
            balances[msg.sender] += msg.value;
            emit Deposit(msg.sender, msg.value);
        }
    }
}