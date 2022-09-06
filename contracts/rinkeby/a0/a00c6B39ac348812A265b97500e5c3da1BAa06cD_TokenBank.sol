// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface MemberToken {
    function balanceOf(address owner) external view returns (uint256);
}

contract TokenBank {
    MemberToken public memberToken;

    /// @dev tokenの名前・シンボル
    string private _name;
    string private _symbol;
    
    /// @dev tokenの総供給量
    uint256 constant _totalSupply = 1000;

    /// @dev tokenを預かっているtokenの総量
    uint256 private _bankTotalDeposit;

    /// @dev TokenBankのオーナーアドレスを格納する。
    address public owner;

    /// @dev アカウントアドレスごとのtoken残高
    mapping(address => uint256) private _balances;

    /// @dev TokenBankが預かっているToken残高
    mapping(address => uint256) _tokenBankBalances;

    /// @dev Token移転時のイベント
    event TokenTrancefer(
        address indexed from,
        address indexed to,
        uint256 ammount
    );

    /// @dev Token預入時のイベント
    event TokenDeposit(
        address indexed from,
        uint256 amount
    );
    /// @dev Token引出時のイベント
    event TokenWithdraw(
        address indexed from,
        uint256 amount
    );

    constructor(
        string memory name_,
        string memory symbol_,
        address nftContract_) {
        _name = name_;
        _symbol = symbol_;
        owner = msg.sender;
        _balances[owner] = _totalSupply;
        memberToken = MemberToken(nftContract_);
    }

    /// @dev NFTメンバーのみ実行可能。
    modifier onlyMember() {
        require(memberToken.balanceOf(msg.sender) > 0, "not NFT member");
        _;
    }

    /// @dev オーナー以外が実行可能
    modifier notOwner() {
        require(owner != msg.sender, "Owner cannot execute!");
        _;
    }

    /// @dev tokenの名前を返すfunction
    function name() public view returns (string memory){
        return _name;
    }
    /// @dev tokenのシンボルを返すfunction
    function symbol() public view returns (string memory){
        return _symbol;
    }

    /// @dev tokenの総供給数を返すfunction（定数の場合はpure）
    function totalSupply() public pure returns (uint256) {
        return _totalSupply;
    } 

    /// @dev 指定したアカウントアドレスのtoken残高を返すfunction
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /// @dev tokenを移転する
    function transfer(address to, uint256 amount) public onlyMember{
        if (msg.sender == owner) {
            require(_balances[owner] - _bankTotalDeposit >= amount, "Amounts greater than the total supply cannnot be transferred");
        }
        address from = msg.sender;
        _transfer(from, to, amount);
    }
    
    /// @dev 実際の移転処理
    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "Zero address cannnot be specified `to`");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "Insufficient balance!");
        _balances[from] = fromBalance - amount;
        _balances[to] += amount;
        emit TokenTrancefer(from, to, amount);
    }
    /// @dev tokenBankが預かっているtokenの総額を返す。
    function bankTotalDeposit() public view returns(uint256) {
        return _bankTotalDeposit;
    }

    /// @dev tokenBankが預かっている指定のアカウントアドレスのToken数を返す
    function bankBalanceOf(address account) public view returns(uint256) {
        return _tokenBankBalances[account];
    }

    /// @dev tokenを預ける。
    function deposit(uint256 amount) public onlyMember notOwner{
        address from = msg.sender;
        address to = owner;
        _transfer(from, to, amount);
        
        _tokenBankBalances[from] += amount;
        _bankTotalDeposit += amount;
        emit TokenDeposit(from, amount);
    }

    /// @dev tokenを引き出す。
    function withDraw(uint256 amount) public onlyMember notOwner{
        address to = msg.sender;
        address from = owner;
        uint256 toTokenBankBalance = _tokenBankBalances[to];
        require(toTokenBankBalance <= amount, "An amount greater than your tokenBank balance!");
        _transfer(from, to, amount);

        _tokenBankBalances[to] -= amount;
        _bankTotalDeposit -= amount;

        emit TokenWithdraw(to, amount);

    }


    








}