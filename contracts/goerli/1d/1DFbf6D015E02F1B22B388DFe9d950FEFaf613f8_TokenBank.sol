// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface MemberToken {
    function balanceOf(address owner) external view returns (uint256);
}

contract TokenBank {
    MemberToken public memberToken;

    /// @dev token's name
    string private _name;

    /// @dev token's symbol
    string private _symbol;

    /// @dev token's total supply
    uint256 constant _totalSupply = 1000;

    /// @dev deposit
    uint256 private _bankTotalDeposit;

    /// @dev owner
    address public owner;

    /// @dev address's balances
    mapping(address => uint256) private _balances;

    /// @dev TokenBank balances
    mapping(address => uint256) private _tokenBankBalances;

    /// @dev token transfer event
    event TokenTransfer(address indexed from, address indexed to, uint256 amount);

    /// @dev token deposit event
    event TokenDeposit(address indexed from, uint256 amount);

    /// @dev token withdraw event
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

    /// @dev only NFT member
    modifier onlyMember() {
        require(memberToken.balanceOf(msg.sender) > 0, "not NFT member");
        _;
    }

    /// @dev not owner
    modifier notOwner() {
        require(owner != msg.sender, "Owner cannot execute");
        _;
    }

    /// @dev get token's name
    function name() public view returns (string memory) {
        return _name;
    }

    /// @dev get token's symbol
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /// @dev get total supply
    function totalSupply() public pure returns (uint256) {
        return _totalSupply;
    }

    /// @dev get target address supply
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /// @dev token transfer
    function transfer(address to, uint256 amount) public onlyMember {
        if (owner == msg.sender) {
            require(_balances[owner] - _bankTotalDeposit >= amount, "Amounts greater than the total supply cannot be trasnferred");
        }
        address from = msg.sender;
        _transfer(from, to, amount);
    }

    /// @dev transfer actual processing
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

    /// @dev get TokenBank has total deposit
    function bankTotalDeposit() public view returns (uint256) {
        return _bankTotalDeposit;
    }

    /// @dev getTokenBank has target address token's
    function bankBalanceOf(address account) public view returns (uint256) {
        return _tokenBankBalances[account];
    }

    /**
     * @dev     token deposit
     * @param   amount  token amount
     */
    function deposit(uint256 amount) public onlyMember notOwner {
        address from = msg.sender;
        address to = owner;
        _transfer(from, to, amount);

        _tokenBankBalances[from] += amount;
        _bankTotalDeposit += amount;
        emit TokenDeposit(from, amount);
    }

    /**
     * @dev     token withdraw
     * @param   amount  token amount
     */
    function withdraw(uint256 amount) public onlyMember notOwner {
        address to = msg.sender;
        address from = owner;
        uint256 toTokenBankBalances = _tokenBankBalances[to];
        require(toTokenBankBalances >= amount, "An amount greater than your tokenBank balance!");
        _transfer(from, to, amount);
        _tokenBankBalances[to] -= amount;
        _bankTotalDeposit -= amount;
        emit TokenWithdraw(to, amount);
    }
}