// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface MNFT{
    function balanceOf(address owner) external view returns (uint256);
}

contract TokenBank{
    // state params;
    MNFT public memberNFT; 
    string private name;
    string private symbol;
    uint256 constant totalSpply = 1000;
    uint256 private bankTotalDeposit;
    address public owner;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _tokenBankBalances;
    /// @dev events
    event transferToken(
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event tokenDeposit(
        address indexed from,
        uint256 amount
    );
    event tokenWithdraw(
        address indexed from,
        uint256 amount
    );

    modifier onlyMember() {
        address owner_  = msg.sender;
        require(memberNFT.balanceOf(owner_)>0, "you are not member");
        _;
    }

    modifier notOwner() {
        require(msg.sender != owner, "you can not do this");
        _;
    }

    constructor(string memory name_, string memory symbol_, address nftContract_) {
        name = name_;
        symbol = symbol_;
        owner = msg.sender;
        _balances[owner] = totalSpply;
        memberNFT = MNFT(nftContract_);
    }

    /// @dev return token name
    function getname() public view returns (string memory){
        return name;
    }
    /// @dev return token symbol
    function getsymbol() public view returns (string memory) {
        return symbol;
    }

    /// @dev return token total supply
    function gettotalsupply() public pure returns (uint256) {
        return totalSpply;
    } 

    /// @dev return address => token
       function balanceOf(address account) public view returns(uint256) {
        return _balances[account];
    }

    /// @dev tranfar token
    function transfer(address to, uint amount) onlyMember public {
        address from = msg.sender;
        if(from == owner) {
            require(balanceOf(from)-bankTotalDeposit >= amount, "grater than you have");
        }
        _transfer(from,to,amount);
    }
    function _transfer(address from, address to, uint256 amount) internal{
        require(to != address(0), "address you sent token is not exist");
        uint256 senderBalance = balanceOf(from);
        require(senderBalance >= amount, "you transfer token more than you have");
        _balances[from] = senderBalance - amount;
        _balances[to] += amount;
        emit transferToken(from, to, amount);
    }
    /// @dev return sum of token this contract have
    function bankTokenBalances() public view returns (uint256) {
        return bankTotalDeposit;
    }
    /// @dev return sum of token args account have in this constract
    function bankBalanceOf(address account) public view returns (uint256) {
        return _tokenBankBalances[account];
    }
    /// @dev deposit token in this contract
    function deposit(uint256 amount) public  onlyMember notOwner{
        address from = msg.sender;
        address to = owner;

        _transfer(from, to, amount);
        bankTotalDeposit += amount;
        _tokenBankBalances[from] += amount;
        emit tokenDeposit(from,amount);
    }

    function withdraw(uint256 amount) public onlyMember notOwner{
        address to = msg.sender;
        address from = owner;
        uint256 toTokenbankBalances = _tokenBankBalances[to];
        require(toTokenbankBalances>=amount,"exceed amount of token you deposit in this contract");
        _transfer(from, to, amount);
        _tokenBankBalances[to] = toTokenbankBalances - amount;
        bankTotalDeposit -= amount;
        emit tokenWithdraw(to,amount);
    } 






}