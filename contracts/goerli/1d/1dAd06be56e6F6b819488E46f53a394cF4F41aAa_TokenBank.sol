// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface MemberToken {
    function balanceOf(address owner) external view returns (uint256);
}

contract TokenBank {
    MemberToken public memberToken;
    
    /// @dev Tokenの名前
    string private _name;

    /// @dev Tokenのシンボル
    string private _symbol;

    /// @dev Tokenの総供給数
    uint256 constant _totalSupply = 1000;

    /// @dev TokenBankが預かっているTokenの総額
    uint256 private _bankTotalDeposit;

    /// @dev TokenBankのオーナー
    address public owner;

    /**
    * @dev 
    * - アカウントアドレス毎のToken残高
    * - アドレスを渡すとToken残高を返す
    */
    mapping(address => uint256) private _balances;

    /// @dev TokenBankが預かっているToken残高
    mapping(address => uint256) private _tokenBankBalances;

    /// @dev Token移転時のイベント
    event TokenTransfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    /// @dev Token預け入れ時のイベント
    event TokenDeposit(
        address indexed from,
        uint256 amount
    );

    /// @dev Token引き出し時のイベント
    event TokenWithdraw(
        address indexed from,
        uint256 amount
    );

    /// @dev コンストラクタは値を変更しなくてもmemory
    constructor (
        string memory name_, 
        string memory symbol_,
        address nftContract_
        ) {
        _name = name_;
        _symbol = symbol_;
        /// @dev コントラクトをデプロイするアドレス
        owner = msg.sender;
        /// @dev Tokenの総額をオーナーに割り当てる
        _balances[owner] = _totalSupply;
        /// @dev memberNFTオブジェクトを使って接続するためのオブジェクト
        memberToken = MemberToken(nftContract_);
    }

    /// @dev NFTメンバーのみ transfer deposit eithdraw
    modifier onlyMember() {
        require(memberToken.balanceOf(msg.sender) > 0, "not NFT member");
        _;
    }

    /// @dev オーナー以外 deposit withdrawはできない自分自身に預ける引き出す意味ない
    modifier notOwner() {
        require(owner != msg.sender, "Owner cannot execute");
        _;
    }
    
    /// @dev Tokenの名前を返す
    function name() public view returns (string memory){
        return _name;
    }

    /// @dev Tokenのシンボルを返す
    function symbol() public view returns (string memory){
        return _symbol;
    }

    /// @dev Tokenの総供給数を返す 定数の場合はpure
    function totalSupply() public pure returns (uint256){
        return _totalSupply;
    }

    /// @dev 指定アカウントアドレスのToken残高を返す
    function balanceOf(address account) public view returns (uint256){
        return _balances[account];
    }

    /// @dev Tokenを移転する
    function transfer(address to, uint amount) public onlyMember{
        if (owner == msg.sender) {
            /// @dev 持ち逃げ防止 ownerの持っている分しかtransferできない
            require(_balances[owner] - _bankTotalDeposit >= amount, "Amounts greater than the total supply cannot be transfered");
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
        /// @dev実行前のバリデーション toがアドレス型の0でなかったら次の処理に進む
        require(to != address(0), "Zoro address cannot be specified for 'to'!");
        uint256 fromBalance = _balances[from];

        require(fromBalance >= amount, "Insufficient balance!");

        _balances[from] = fromBalance - amount;
        _balances[to] += amount;

        emit TokenTransfer(from, to, amount);
    }

    /// @dev TokenBankが預かっているTokenの残高を返す
    function bankTotalDeposit() public view returns (uint256) {
        return _bankTotalDeposit;
    }

    /// @dev TokenBankが預かっている指定のアカウントアドレスのTokenの数を返す
    function bankBalanceOf(address account) public view returns (uint256) {
        return _tokenBankBalances[account];
    }

    /// @dev Tokenを預ける 銀行はTokenBankのオーナーアドレス
    function deposit(uint256 amount) public onlyMember notOwner{
        address from = msg.sender;
        address to = owner;

        _transfer(from, to, amount);

        _tokenBankBalances[from] += amount;
        _bankTotalDeposit += amount;
        emit TokenDeposit(from, amount);
    }

    /// @dev Tokenを引き出す 
    function withdraw(uint256 amount) public onlyMember notOwner{
        address to = msg.sender;
        address from = owner;
        uint256 toTokenBankBalance = _tokenBankBalances[to];
        require(toTokenBankBalance >= amount, "An amount greater than your token balanace!");
        _transfer(from, to, amount);
        _tokenBankBalances[to] -= amount;
        _bankTotalDeposit -= amount;
        emit TokenWithdraw(to, amount);
    }
}