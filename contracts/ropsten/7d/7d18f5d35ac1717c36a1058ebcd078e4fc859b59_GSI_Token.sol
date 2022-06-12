/*
* MIT License
*
* Copyright (c) 2022 Giant Shiba Inu
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
*
* █████▀██████████████████████████████████████████████████████████████████████████
* █─▄▄▄▄█▄─▄██▀▄─██▄─▀█▄─▄█─▄─▄─███─▄▄▄▄█─█─█▄─▄█▄─▄─▀██▀▄─████▄─▄█▄─▀█▄─▄█▄─██─▄█
* █─██▄─██─███─▀─███─█▄▀─████─█████▄▄▄▄─█─▄─██─███─▄─▀██─▀─█████─███─█▄▀─███─██─██
* █▄▄▄▄▄█▄▄▄█▄▄█▄▄█▄▄▄██▄▄██▄▄▄████▄▄▄▄▄█▄█▄█▄▄▄█▄▄▄▄██▄▄█▄▄███▄▄▄█▄▄▄██▄▄██▄▄▄▄██
* ████████████████████████████████████████████████████████████████████████████████
*
*
* @title GSI Token Contract [Binance Smart Chain]
*
* @author Rajesh Kumar Roy | A & N Islands, India
*
* @notice This token contract shall be initially minted on BSC with a
*         supply of 1,000,000,000,000 but it shall be available on four 
*         other blockchains with 0 (zero) initial supply.
* @dev "Auth" modifier was used to give permission to the staking contract
*      to burn/mint tokens from the liquidity pool.
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./iGSI.sol";

contract GSI_Token is iGSI
{
    address private _owner;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowed;
    mapping(address => bool) private _isRegdAddr;
    mapping(address => string) private _password;

    constructor()
    {
        _owner = msg.sender;

        _name = "Giant Shiba Inu";
        _symbol = "GSI";
        _decimals = 18;
        _totalSupply = 1000000000000 * (10 ** _decimals);

        _balance[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    function name() external view returns (string memory)
    {
        return _name;
    }

    function symbol() external view returns (string memory)
    {
        return _symbol;
    }

    function decimals() external view returns (uint8)
    {
        return _decimals;
    }

    function totalSupply() external view returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256)
    {
        return _balance[account];
    }

    function allowance(address owner, address spender) external view returns (uint256)
    {
        return _allowed[owner][spender];
    }

    function transfer(address account, uint256 amount) external returns (bool)
    {
        require(_balance[msg.sender] > 0, "Zero Balance!");
        require(_balance[msg.sender] >= amount, "Low Balance!");

        _balance[msg.sender] -= amount;
        _balance[account] += amount;
        emit Transfer(msg.sender, account, amount);

        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool)
    {
        _allowed[msg.sender][spender] += amount;
        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transferFrom(address spender, address recipient, uint256 amount) external returns (bool)
    {
        require(_balance[spender] > 0, "Zero Balance!");
        require(_balance[spender] >= amount, "Low Balance!");

        _allowed[spender][msg.sender] -= amount;
        _balance[spender] -= amount;
        _balance[recipient] += amount;
        emit Transfer(spender, recipient, amount);

        return true;
    }

    modifier onlyOwner
    {
        require(msg.sender == _owner, "Permission Denied, You're not the Contract Owner!");
        _;
    }

    function regAddr(address account) onlyOwner external returns (bool)
    {
        require(!_isRegdAddr[account], "Address already Registered!");

        _isRegdAddr[account] = true;

        return true;
    }

    function deRegAddr(address account) onlyOwner external returns (bool)
    {
        require(_isRegdAddr[account], "Address not Registered!");

        _isRegdAddr[account] = false;

        return true;
    }

    modifier Auth(string memory password)
    {
        require(_isRegdAddr[msg.sender], "Permission Denied, Address not Registered!");
        require(keccak256(abi.encodePacked(password)) == keccak256(abi.encodePacked(_password[msg.sender])), "Authentication Failed, Wrong Password!");
        _;
    }

    function mint(address account, uint256 amount, string memory password) Auth(password) external returns (bool)
    {
        _totalSupply += amount;
        _balance[account] += amount;
        emit Transfer(msg.sender, account, amount);

        return true;
    }

    function burn(address account, uint256 amount, string memory password) Auth(password) external returns (bool)
    {
        require(_balance[account] > 0, "Zero Balance!");
        require(_balance[account] >= amount, "Low Balance!");

        _totalSupply -= amount;
        _balance[account] -= amount;
        emit Transfer(msg.sender, account, amount);

        return true;
    }
}