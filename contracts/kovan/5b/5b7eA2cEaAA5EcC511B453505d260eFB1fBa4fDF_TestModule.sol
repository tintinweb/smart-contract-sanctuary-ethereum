/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

contract TestModule {

    uint public amount;

    event Staked(address indexed staker, address spender, uint256 amount);
    event WithdrewStake(address indexed staker, address recipient, uint256 amount);
    event WithdrewDebt(address indexed staker, address recipient, uint256 amount, uint256 newDebtBalance);

    function setAmount(uint _amount) external {
        amount = _amount;
    }

    function emitStakedEvent(address _spender) external {
        emit Staked(msg.sender, _spender, amount);
    }

    function emitWithdrewStake(address _recipient) external {
        emit WithdrewStake(msg.sender, _recipient, amount);
    }

    function emitWithdrewDebt(address _recipient, uint _newDebtBalance) external {
        emit WithdrewDebt(msg.sender, _recipient, amount, _newDebtBalance);
    }
}