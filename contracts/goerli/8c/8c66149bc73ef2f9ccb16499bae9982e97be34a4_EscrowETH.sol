/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface USDC 
{
    function totalSuply() external view returns(uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract EscrowETH 
{
    // public variables
    address private _owner;
    USDC public usdc;
    address private _usdcAddress;
    uint256 private _power;
    // contract balance variables
    uint256 private _contractBalance; 
    uint256 private _totalDepositBalance;
    uint256 private _totalWithdrawBalance;
    // users balance variables
    mapping(address => uint) private _userBalance;
    mapping(address => uint) private _userDeposit;
    mapping(address => uint) private _userWithdraw;

    constructor() 
    {
        _usdcAddress = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
        usdc = USDC(_usdcAddress);
        _owner = msg.sender;
        _contractBalance = 0;
        _totalDepositBalance = 0;
        _totalWithdrawBalance = 0;
        _power = 10 ** 6;
    }

    // deposit from users
    function deposit(uint amount) external returns(bool) 
    {
        require (amount * _power > 0 , "amount should be > 0");
        _contractBalance += amount * _power;
        _totalDepositBalance += amount * _power;
        _userBalance[msg.sender] += amount * _power;
        _userDeposit[msg.sender] += amount * _power;
        usdc.transfer(address(this), amount * _power);
        return true;
    }

    // withdraw from users
    function withdraw(uint amount)external returns(bool) 
    {
        require (amount * _power > 0 , "amount should be > 0");
        require(_contractBalance > amount * _power , "The balance of the contract is not enough");
        _contractBalance -= amount * _power;
        _totalWithdrawBalance -= amount * _power;
        _userBalance[msg.sender] -= amount * _power;
        _userWithdraw[msg.sender] -= amount * _power;
        usdc.transfer(msg.sender, amount * _power);
        return true;
    }

    // admin send to users wallet
    function adminSend(uint amount, address to)external returns(bool) 
    {
        require(msg.sender == _owner , "Only owner can call this function");
        require(_contractBalance > amount * _power , "The balance of the contract is not enough");
        require (amount * _power > 0 , "amount should be > 0");
        _contractBalance -= amount * _power;
        _userWithdraw[to] += amount * _power;
        usdc.transferFrom(address(this), to, amount * _power);
        return true;
    }

    // return contract balance (current balance)
    function balance()public view returns(uint256) 
    {
        return _contractBalance;
    }

    // return contract deposit balance
    function totalDepositBalance()public view returns(uint256) 
    {
        return _totalDepositBalance;
    }

    // return contract withdraw balance
    function totalWithdrawBalance()public view returns(uint256) 
    {
        return _totalWithdrawBalance;
    }

    // change contract owner
    function changeOwner(address newOwner) external returns(bool) 
    {
        require(msg.sender == _owner , "Only owner can call this function");
        _owner = newOwner;
        return true;
    }

    // return contract owner
    function getOwner() external view returns(address)
    {
        return _owner;
    }

    // return user balance 
    function userBalance(address _userWallet) external view returns(uint256)
    {
        uint256 _balance = _userBalance[_userWallet];
        return _balance;
    }

    // return total deposit of user
    function userDeposit(address _userWallet) external view returns(uint256)
    {
        uint256 _balance = _userDeposit[_userWallet];
        return _balance;
    }

    // return total withdraw of user
    function userWithdraw(address _userWallet) external view returns(uint256)
    {
        uint256 _balance = _userWithdraw[_userWallet];
        return _balance;
    }

}