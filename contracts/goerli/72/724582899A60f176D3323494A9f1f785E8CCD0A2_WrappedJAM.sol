/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// Copyright (C) 2015, 2016, 2017 Dapphub

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.0;

contract WrappedJAM {
    string public name = "Wrapped JAM";
    string public symbol = "WJAM";
    uint8 public decimals = 18;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
    event Transfer(
        address indexed sender,
        address indexed recipient,
        uint256 amount
    );
    event Wrapped(address indexed user, uint256 amount);
    event Unwrapped(address indexed user, uint256 amount);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    receive() external payable {
        wrap();
    }

    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    function balanceOf(address user) external view returns (uint256) {
        return _balances[user];
    }

    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function wrap() public payable {
        _balances[msg.sender] += msg.value;
        emit Wrapped(msg.sender, msg.value);
    }

    function unwrap(uint256 amount) public {
        require(
            _balances[msg.sender] >= amount,
            "WrappedJAM: not enough Wrapped JAM"
        );
        _balances[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "WrappedJAM: unwrap failed");
        emit Unwrapped(msg.sender, amount);
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        return transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        require(
            _balances[sender] >= amount,
            "WrappedJAM: transfer amount exceeds balance"
        );
        if (
            sender != msg.sender &&
            _allowances[sender][msg.sender] != type(uint256).max
        ) {
            require(
                _allowances[sender][msg.sender] >= amount,
                "WrappedJAM: insufficient allowance"
            );
            _allowances[sender][msg.sender] -= amount;
        }
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
}