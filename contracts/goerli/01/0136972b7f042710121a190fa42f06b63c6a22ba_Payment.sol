/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Payment {
    mapping(address => uint256) private _balance;

    function pay(address _account, uint56 _amount) public {
        _balance[_account] += _amount;
    }

    function balanceOf(address _account) public view returns(uint256) {
        return _balance[_account];
    }
}