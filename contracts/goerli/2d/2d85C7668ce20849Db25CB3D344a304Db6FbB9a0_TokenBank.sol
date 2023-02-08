// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

//コントラクト名と同じだとテストが通らなくなる
interface MemberToken {
    function balanceOf(address owner) external view returns (uint256);
}

contract TokenBank {
    MemberToken public memberToken;


    //Tokenの名前
    string private _name;

    //Tokenのシンボル
    string private _symbol;

    //Tokenの総供給量,全てのトークンの数constantは定数を表す、初期値が必要。
    uint256 constant _totalSuply = 1000;

    //TokenBankが預かっているTokenの総数
    uint256 private _bankTotalDeposit;

    //TokenBankのオーナー
    //publicの状態変数はSolidityが自動的にgetter関数を作ってくれる、よってここでownerを返す関数を書かなくても、自動的に作られたowner()という関数を外から呼ぶことができる
    address public owner;

    //アカウントアドレスごとのToken残高
    mapping(address => uint256) private _balances;

    //TokenBankが預かっているToken残高、アカウントアドレスごとの預金額？
    mapping(address => uint256) private _tokenBankBalances;

    //Token移転時のイベント
    event TokenTransfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    //Token預入時のイベント
    event TokenDeposit(
        address indexed from, 
        uint256 amount
    );

    //Token引き出し時のイベント
    event TokenWithdraw(
        address indexed from, 
        uint256 amount
    );

    // コンストラクタの場合は変更しなくてもmemory
    constructor(string memory name_, string memory symbol_, address nftContract_) {
        _name = name_;
        _symbol = symbol_;
        owner = msg.sender;
        _balances[owner] = _totalSuply;
        memberToken = MemberToken(nftContract_);
    }

    //NFTメンバーのみ(NFTを持っている人のみ)
    modifier onlyMember() {
        require(memberToken.balanceOf(msg.sender) > 0, "not NFT member");
        _;
    }

    //オーナー以外
    modifier notOwner() {
        require(owner != msg.sender, "Owner cannot execute");
        _;
    }

    //Tokenの名前を返す
    function name() public view returns(string memory) {
        return _name;
    }

    //Tokenのシンボルを返す
    function symbol() public view returns(string memory) {
        return _symbol;
    }

    //Tokenの総供給数を返す
    //定数を返す場合はpure修飾子
    function totalSuply() public pure returns(uint256) {
        return _totalSuply;
    }

    //指定アカウントアドレスのToken残高を返す
    function balanceOf(address account) public view returns(uint256) {
        return _balances[account];
    }

    //Tokenを移転する
    function transfer(address to, uint256 amount) public onlyMember{
        if (owner == msg.sender) {
            //ここよくわからん
            require(_balances[owner] - _bankTotalDeposit >= amount, "Amounts greater than total supply cannot be transferred");
        }
        address from = msg.sender;
        _transfer(from, to, amount); 
    }

    // 実際の移転処理
    function _transfer(address from, address to, uint256 amount) internal {
        require (to != address(0), "Zero Address cannot be specified 'to'!");
        uint256 fromBalance = _balances[from];

        require(fromBalance >= amount, "Insuffciant balance!");

        _balances[from] = fromBalance - amount;

        _balances[to] += amount;

        emit TokenTransfer(from, to, amount);
    }

    //TokenBankが預かっているTokenの総数を返す
    function bankTotalDeposit() public view returns(uint256) {
        return _bankTotalDeposit;
    }

    //TokenBankが預かっている指定のアカウントのTokenの総数を返す
    function bankBalanceOf(address account) public view returns(uint256) {
        return _tokenBankBalances[account];
    }

    //バンクにトークンを預ける
    function deposit(uint256 amount) public onlyMember notOwner{
        address from = msg.sender;
        address to = owner;

        _transfer(from, to, amount);

        _tokenBankBalances[from] += amount;
        _bankTotalDeposit += amount;

        emit TokenDeposit(from, amount);
    } 

    //バンクからトークンを引き出す
    function withdraw(uint256 amount) public onlyMember notOwner{
        address to = msg.sender;
        address from = owner;
        uint256 toTokenBankBalance = _tokenBankBalances[to];
        require(toTokenBankBalance >= amount, "An amount greater than your tokenBank balance");
        _transfer(from, to, amount);
        _tokenBankBalances[to] -= amount;
        _bankTotalDeposit -= amount;
        emit TokenWithdraw(to, amount);
    }
}