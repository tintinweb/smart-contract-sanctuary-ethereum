// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract TokenBank {
    // Tokenの名前
    string private _name;

    // Tokenのシンボル
    string private _symbol;

    // Tokenの総供給量
    uint256 private _totalSupply = 1000;

    // TokenBankが預かっているTokenの総額
    uint256 private _bankTotalSupply;

    // TokenBankのオーナー
    address public owner;

    // アカウントアドレス毎のToken残高
    mapping(address => uint256) private _balances;

    // TokenBankが預かっているToken残高
    mapping(address => uint256) private _tokenBankBalances;

    // Token移転時のイベント
    event TokenTransfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    // Tokenを預けるイベント
    event TokenDeposit(address indexed from, uint256 amount);

    // Tokenを引き出すイベント
    event TokenWithdraw(address indexed from, uint256 amount);

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        owner = msg.sender;
        _balances[owner] = _totalSupply;
    }

    // Tokenの名前を返す
    function name() public view returns (string memory) {
        return _name;
    }

    // Tokenのシンボルを返す
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // Tokenの総供給量を返す
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // 指定アカウントアドレスのTokenの残高を返す
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    // Tokenを移転する
    function transfer(address to, uint256 amount) public {
        address from = msg.sender;
        _transfer(from, to, amount);
    }

    // 実際の移転処理
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(to != address(0), "Zero address cannot be specified for 'to'!");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "Insufficient balance!");
        _balances[from] = fromBalance - amount;
        _balances[to] += amount;
        emit TokenTransfer(from, to, amount);
    }

    // TokenBankが預かっているTokenの総額を返す
    function bankTotalSupply() public view returns (uint256) {
        return _bankTotalSupply;
    }

    // TokenBankが預かっているTokenの残高を返す
    function bankBalanceOf(address account) public view returns (uint256) {
        return _tokenBankBalances[account];
    }

    // Tokenを預ける
    function deposit(uint256 amount) public {
        address from = msg.sender;
        address to = owner;

        _transfer(from, to, amount);

        _tokenBankBalances[from] += amount;
        _bankTotalSupply += amount;

        emit TokenDeposit(from, amount);
    }

    // Tokenを引き出す
    function withdraw(uint256 amount) public {
        address to = msg.sender;
        address from = owner;
        uint256 toTokenBankBalance = _tokenBankBalances[to];
        require(
            toTokenBankBalance >= amount,
            "An amount greater than your tokenBank balance!"
        );

        _transfer(from, to, amount);

        _tokenBankBalances[to] -= amount;
        _bankTotalSupply -= amount;

        emit TokenWithdraw(to, amount);
    }
}