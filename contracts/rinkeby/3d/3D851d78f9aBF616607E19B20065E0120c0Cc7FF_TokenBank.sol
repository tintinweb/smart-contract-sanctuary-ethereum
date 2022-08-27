// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface MemberToken {
    //MemberNFTが所持しているNFTの個数を返す。balanceOfはERC721.solに規定
    function balanceOf(address owner) external view returns (uint256);
}

contract TokenBank {
    //状態変数の定義----------------------------------------------------------------------
    MemberToken public memberToken;

    /// @dev Tokenの名前
    string private _name;

    /// @dev Tokenのシンボル
    string private _symbol;

    /// @dev Tokenの総供給量数 定数なのでconstantにする
    uint256 constant _totalSupply = 1000;

    /// @dev TokenBnakが預かっているTokenの総額
    uint256 private _bankTotalDeposit;

    /// @dev TokenBankのオーナーのアドレスを格納
    address public owner;

    //マッピング----------------------------------------------------------------------

    /// @dev アカウントアドレスごとのToken残高 addressを入力するとuint256型が返ってくる
    mapping(address => uint256) private _balances;

    /// @dev TokenBankが預かっているToken残高
    mapping(address => uint256) private _tokenBankBalances;

    //イベント（記録）----------------------------------------------------------------------

    /// @dev Token移転時のイベント
    event TokenTransfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    /// @dev Token預入時のイベント
    event TokenDeposit(address indexed from, uint amount);

    /// @dev Token引出時のイベント
    event TokenWithdraw(address indexed from, uint amount);

    //型の定義----------------------------------------------------------------------

    /////////////////////////////////////////////////////////////////
    constructor(
        string memory name_,
        string memory symbol_,
        address nftContract_
    ) {
        _name = name_;
        _symbol = symbol_;
        owner = msg.sender; //デプロイ（署名）するときのアドレス
        _balances[owner] = _totalSupply; //_balances[owner]：オーナーの持っている残高uint256型
        memberToken = MemberToken(nftContract_); //特定のメンバーのみアクセス権を付与するための準備
    }

    /////////////////////////////////////////////////////////////////

    //制限----------------------------------------------------------------------

    /// @dev NFTメンバーのみ。制限したい処理（function）にonlyMenberを加える（visibilityの後ろ）ことで処理の実行制限がかけられる
    modifier onlyMenber() {
        require(memberToken.balanceOf(msg.sender) > 0, "not NFT member");
        _; //後続処理
    }

    /// @dev オーナー以外
    modifier notOwner() {
        require(owner != msg.sender, "Owner cannot execute");
        _; //後続処理
    }

    //関数----------------------------------------------------------------------

    /// @dev Tokenの名前を返す
    function name() public view returns (string memory) {
        return _name;
    }

    /// @dev Tokenのシンボルを返す
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /// @dev Tokenの総供給数を返す 定数を返すので「pure」を使う
    function totalSupply() public pure returns (uint256) {
        return _totalSupply;
    }

    /// @dev 指定アカウントアドレスのToken残高を返す addressをaccountで受け取る
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /// @dev Tokenを移転する
    function transfer(address to, uint256 amount) public onlyMenber {
        if(owner == msg.sender){
            //オーナーが預入している量までしか取引できないようにする
            require(_balances[owner] - _bankTotalDeposit >= amount, "Amounts greater than the total supply cannot be transferred");
        }
        address from = msg.sender;
        _transfer(from, to, amount);
    }

    /// @dev 実際の移転処理
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(to != address(0), "Zero address cannot be specified for 'to'");
        uint256 fromBalance = _balances[from]; //from 送り手の残高

        require(fromBalance >= amount, "Insufficient balance!");

        _balances[from] = fromBalance - amount;
        _balances[to] += amount;
        emit TokenTransfer(from, to, amount); //41
    }

    //以下二つの関数はprivateで定義されている変数をpublicで返すもの
    /// @dev TokenBankが預かっているTokenの総額を返す
    function bankTotalDeposit() public view returns (uint256) {
        return _bankTotalDeposit;
    }

    /// @dev TokenBankが預かっている指定アカウントアドレスのToken数を返す
    function bankBalanceOf(address account) public view returns (uint256) {
        return _tokenBankBalances[account];
    }

    /// @dev Tokenを預ける
    function deposit(uint256 amount) public onlyMenber notOwner {
        address from = msg.sender;
        address to = owner;

        _transfer(from, to, amount); //104

        _tokenBankBalances[from] += amount;
        _bankTotalDeposit += amount;
        emit TokenDeposit(from, amount); //48
    }

    /// @dev Tokenを引き出す
    function withdraw(uint256 amount) public onlyMenber notOwner {
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