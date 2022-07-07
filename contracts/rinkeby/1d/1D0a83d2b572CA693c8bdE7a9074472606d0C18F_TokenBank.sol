// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface MemberToken {
    function nftMint(address to, string calldata uri) external;

    function balanceOf(address member) external view returns (uint256 balance);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract TokenBank {
    MemberToken public memberNFT;

    // Tokenの名前
    string private _name;

    // Tokenのシンボル
    string private _symbol;

    // Tokenの総供給量
    uint256 constant _totalSupply = 1000;

    // TokenBankが預かっているTokenの総額
    uint256 private _bankTotalDeposit;

    // TokenBankのオーナー
    address public owner = 0xC366ca6dcca1F077E69d6E1ed007feCF489f170C;

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

    constructor(
        string memory name_,
        string memory symbol_,
        address nftContract_
    ) {
        _name = name_;
        _symbol = symbol_;
        _balances[owner] = _totalSupply;
        memberNFT = MemberToken(nftContract_);
    }

    // NFTメンバー
    modifier Member() {
        require(memberNFT.balanceOf(msg.sender) > 0, "not NFT Members");
        _;
    }

    // Tokenオーナー以外
    modifier notOwner() {
        require(owner != msg.sender, "Owner cannot execute");
        _;
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
    function totalSupply() public pure returns (uint256) {
        return _totalSupply;
    }

    // 指定アカウントアドレスのTokenの残高を返す
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    // Tokenを移転する
    function transfer(address to, uint256 amount) public {
        if (owner == msg.sender) {
            require(
                _balances[owner] - _bankTotalDeposit >= amount,
                "Amounts greater than the total supply cannot be transferred"
            );
        }

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
    function bankTotalDeposit() public view returns (uint256) {
        return _bankTotalDeposit;
    }

    // TokenBankが預かっているTokenの残高を返す
    function bankBalanceOf(address account) public view returns (uint256) {
        return _tokenBankBalances[account];
    }

    // Tokenを預ける
    function deposit(uint256 amount) public notOwner Member {
        address from = msg.sender;
        address to = owner;

        _transfer(from, to, amount);

        _tokenBankBalances[from] += amount;
        _bankTotalDeposit += amount;

        emit TokenDeposit(from, amount);
    }

    // Tokenを引き出す
    function withdraw(uint256 amount) public notOwner {
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