//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

///@dev interface
interface IFmemberNFT {
    function balanceOf(address owner) external view  returns (uint256);
}


///@dev tokenとは仮想通貨のようなもの
contract TokenBank {
    IFmemberNFT iFmemberNFT;


    string private _name;   ///@dev token name
    string private _symbol;   ///@dev token symbol
    uint constant _totalSupply = 1000;   ///@dev total 流通token量
    uint private _totalDeposit;   ///@dev bankが預かっているtoken量
    address public owner;   ///@dev オーナーのaddress

    mapping(address => uint) private _balanceOfEachAddress;   ///@dev 各々のアカウント(address)が持っているtoken量
    mapping(address => uint) private _depositOfEachAddress;   ///@dev 各々のアカウントが預けているtoken量

     /// @dev Token移転時のイベント
    event Transfer(
        address indexed from,
        address indexed to,
        uint amount
    );

     /// @dev Token預入時のイベント
    event Deposit(
        address indexed from,
        uint amount
    );

     /// @dev Token引出時のイベント
    event Withdraw(
        address indexed to,
        uint amount
    );

    /// constructorの定義
    constructor(string memory name_, string memory symbol_, address ifmemberNFTaddress_) {
        _name = name_;
        _symbol = symbol_;
        owner = msg.sender;
        _balanceOfEachAddress[owner] = _totalSupply;
        iFmemberNFT = IFmemberNFT(ifmemberNFTaddress_);
    }

    ///modifier NFTmemberのみ
    modifier onlyMember(){
        require(iFmemberNFT.balanceOf(msg.sender) > 0, "ONLY MEMBER CAN TRANSACT");
        _;
    }

    ///modifier ownerはDEPOSITやWITHDRAWできない
    modifier notOwner(){
        require(msg.sender != owner,"THE OWNER CAN NEITHER DEPONIST NOR WITHDRAW");
        _;
    }

    /// @dev Tokenの名前を返す
    function name() public view returns(string memory){
        return _name;
    }

    function symbol() public view returns(string memory){
        return _symbol;
    }

    function totalSupply() public pure returns(uint){
        return _totalSupply;
    }

    ///@dev 各アカウントが持っているtoken量を返す
    function balanceOf(address addr_) public view returns(uint){
        return _balanceOfEachAddress[addr_];
    }

    ///@dev tokenを移転する address fromはmsg.sender
    function transfer(address to, uint amount) public onlyMember {
        _transfer(msg.sender,to,amount);
    }

    ///
    function _transfer(address from, address to, uint amount) internal {
        require(to != address(0),"cannot send to ZERO address" ); /// zero addressには送れない
        require(_balanceOfEachAddress[from] >= amount, "balance deficiency"); /// 残高不足では送れない
        _balanceOfEachAddress[from] -= amount; ///
        _balanceOfEachAddress[to] += amount;
        emit Transfer(from, to, amount);
    }

    ///@dev tokenbankが預かっているtoken総額を返す
    function totalDeposit() public view returns(uint){
        return _totalDeposit;
    }
    
    ///@dev tokenbankが預かっている各アカウントのdepositを返す
    function depositOf(address addr_) public view returns(uint){
        return _depositOfEachAddress[addr_];
    }

    ///@dev 預け入れ関数の外面
    function deposit(uint amount) public onlyMember notOwner {
        _transfer(msg.sender, owner, amount);
        _totalDeposit += amount;
        _depositOfEachAddress[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    ///@dev address from = msg.sender, address to = owner
    function withdraw(uint amount) public onlyMember notOwner {
        require(_depositOfEachAddress[msg.sender]>= amount,"deposit deficiency");
        _transfer(owner, msg.sender, amount);
        _totalDeposit -= amount;
        _depositOfEachAddress[msg.sender] -= amount;
        emit Withdraw(msg.sender, amount);
    }
}