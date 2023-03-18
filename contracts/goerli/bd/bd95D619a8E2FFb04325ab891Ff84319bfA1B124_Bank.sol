// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {BankErrors} from "./interface/BankErrors.sol";
import {IBank} from "./interface/IBank.sol";

contract Bank is IBank, BankErrors {
    mapping(address => uint256) public balances;

    event Deposit(address indexed addr, uint256 amount);
    event Withdrawal(address indexed addr, uint256 amount);

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        unchecked {
            balances[msg.sender] += msg.value;
        }
        emit Deposit(msg.sender, msg.value);
    }

    function withdrawPartial(uint256 amount) public {
        if (balances[msg.sender] < amount) {
            revert InsufficientFunds({requested: amount, available: balances[msg.sender]});
        }
        balances[msg.sender] -= amount;
        (bool succ,) = msg.sender.call{value: amount}("");
        if (!succ) revert WithdrawFailed();
        emit Withdrawal(msg.sender, amount);
    }

    function withdraw() public {
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool succ,) = msg.sender.call{value: amount}("");
        if (!succ) revert WithdrawFailed();
        emit Withdrawal(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface BankErrors {
    error InsufficientFunds(uint256 requested, uint256 available);

    error WithdrawFailed();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBank {
    function deposit() external payable;

    function withdraw() external;

    function withdrawPartial(uint256 amount) external;

    function balances(address addr) external view returns (uint256);
}