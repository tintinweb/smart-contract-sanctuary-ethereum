// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface MemberToken {
    function balanceOf(address owner) external view returns (uint256);
}

contract TokenBank {
    /// @dev [MemberNFT.sol]参照用変数.
    MemberToken public memberToken;

    /// @dev Token名.
    string private _name;

    /// @dev Tokenシンボル.
    string private _symbol;

    /// @dev Token総供給数.
    uint256 constant _totalSupply = 1000;

    /// @dev TokenBankが預かっているToken総額.
    uint256 private _bankTotalDeposit;

    /// @dev TokenBankオーナー.
    address public owner;

    /// @dev アカウントアドレスごとのToken残高.
    mapping(address => uint256) private _balances;

    /// @dev TokenBankが預かっているToken残高.
    mapping(address => uint256) private _tokenBankBalances;

    /// @dev Token移転時のイベント.
    event TokenTransfer (
        address indexed from,
        address indexed to,
        uint256 amount
    );

    /// @dev Token預入時のイベント.
    event TokenDeposit (
        address indexed from,
        uint256 amount
    );

    /// @dev Token引出時のイベント.
    event TokenWithdraw (
        address indexed from,
        uint256 amount
    );

    constructor (string memory name_, string memory symbol_, address nftContract_) {
        _name = name_;
        _symbol = symbol_;
        owner = msg.sender;
        _balances[owner] = _totalSupply;
        memberToken = MemberToken(nftContract_);
    }

    /// @dev NFTメンバーのみ.
    modifier onlyMember() {
        require(memberToken.balanceOf(msg.sender) > 0, "Not NFT member.");
        _;
    }

    /// @dev オーナー以外.
    modifier notOwner() {
        require(owner != msg.sender, "Owner cannot execute.");
        _;
    }

    /// @dev Tokenの名前を返す.
    function name() public view returns (string memory) {
        return _name;
    }

    /// @dev Tokenのシンボルを返す.
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /// @dev Token総供給数を返す.
    function totalSupply() public pure returns (uint256) {
        return _totalSupply;
    }

    /// @dev 指定アドレスのToken残高を返す.
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /// @dev Tokenを移転.
    function transfer(address to, uint256 amount) public onlyMember {
        if(owner == msg.sender) {
            require(_balances[owner] - _bankTotalDeposit >= amount, "Total supplies above amount cannot be transferred.");
        }
        address from = msg.sender;
        _transfer(from, to, amount);
    }

    /// @dev Tokenを移転.
    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "Zero addresses shall be excluded from the transfer.");
        require(_balances[from] >= amount, "The balance of virtual currency in your possession is insufficient.");
        _balances[from] -= amount;
        _balances[to] += amount;

        emit TokenTransfer(from, to, amount);
    }

    /// @dev TokenBankが預かっているTokenの総額を返す.
    function bankTotalDeposit() public view returns (uint256) {
        return _bankTotalDeposit;
    }

    /// @dev TokenBankが預かっている指定アドレスのTokenの総額を返す.
    function bankBalanceOf(address account) public view returns (uint256) {
        return _tokenBankBalances[account];
    }

    /// @dev Tokenを預ける.
    function deposit(uint256 amount) public onlyMember notOwner {
        address from = msg.sender;
        address to = owner;

        _transfer(from, to, amount);

        _tokenBankBalances[from] += amount;
        _bankTotalDeposit += amount;

        emit TokenDeposit(from, amount);
    }

    /// @dev Tokenを引き出す.
    function withdraw(uint256 amount) public onlyMember notOwner {
        address to = msg.sender;
        address from = owner;
        uint256 tokenBankBalance = _tokenBankBalances[to];
        require(tokenBankBalance >= amount, "An amount is greater than your tokenBank balance.");

        _transfer(from, to, amount);

        _tokenBankBalances[to] -= amount;
        _bankTotalDeposit -= amount;

        emit TokenWithdraw(to, amount);
    }
}