// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface MemberToken {
    function balanceOf(address owner) external view returns (uint256);
}

contract TokenBank {
    MemberToken public memberToken;

    // token name
    string private _name;

    // token symbol
    string private _symbol;

    // token total supply
    uint256 constant _totalSupply = 1000;

    // total number of tokens that the token bank has
    uint256 private _bankTotalDeposit;

    // owner of the token bank
    address public owner;

    // balance of a account
    mapping(address => uint256) private _balances;

    // balance that the token bank keeps
    mapping(address => uint256) private _tokenBankBalances;

    event TokenTransfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    // only member who has MemberNFT
    modifier onlyMember() {
        require(memberToken.balanceOf(msg.sender) > 0, "not NFT member");
        _;
    }

    // not owner
    modifier notOwner() {
        require(owner != msg.sender, "Owner cannot execute");
        _;
    }

    event TokenDeposit(address indexed from, uint256 amount);

    event TokenWithdraw(address indexed from, uint256 amount);

    constructor(
        string memory name_,
        string memory symbol_,
        address nftContract_
    ) {
        _name = name_;
        _symbol = symbol_;
        owner = msg.sender;
        _balances[owner] = _totalSupply;
        memberToken = MemberToken(nftContract_);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public pure returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public onlyMember {
        if (owner == msg.sender) {
            require(
                _balances[owner] - _bankTotalDeposit >= amount,
                "Amounts greater than the total supply cannot be transferred"
            );
        }
        address from = msg.sender;
        _transfer(from, to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(to != address(0), "Zero address cannot be specified for 'to'");
        uint256 fromBalance = _balances[from];

        require(fromBalance >= amount, "Insufficient balance!");
        _balances[from] = fromBalance - amount;
        _balances[to] += amount;

        emit TokenTransfer(from, to, amount);
    }

    // deposit
    function bankTotalDeposit() public view returns (uint256) {
        return _bankTotalDeposit;
    }

    function bankBalanceOf(address account) public view returns (uint256) {
        return _tokenBankBalances[account];
    }

    function deposit(uint256 amount) public onlyMember notOwner {
        address from = msg.sender;
        address to = owner;

        _transfer(from, to, amount);

        _tokenBankBalances[from] += amount;
        _bankTotalDeposit += amount;
        emit TokenDeposit(from, amount);
    }

    // withdraw
    function withdraw(uint256 amount) public onlyMember notOwner {
        address to = msg.sender;
        address from = owner;
        uint256 toTokenBankBalance = _tokenBankBalances[to];
        require(
            toTokenBankBalance >= amount,
            "An amount greater than your tokenBank balance!"
        );

        _transfer(from, to, amount);
        _tokenBankBalances[to] -= amount;
        _bankTotalDeposit -= amount;
        emit TokenWithdraw(to, amount);
    }
}