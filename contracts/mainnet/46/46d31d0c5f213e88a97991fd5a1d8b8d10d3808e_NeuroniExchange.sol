/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address _owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract NeuroniExchange {

    address public owner;
    bool public depositEnabled;
    bool public withdrawEnabled;
    address public fromTokenAddress;
    address public toTokenAddress;

    IERC20 private _fromToken;
    IERC20 private _toToken;

    mapping(address => uint256) public balances;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "no permissions");
        _;
    }
       
    modifier isDepositEnabled() {
        require(depositEnabled, "Deposit not enabled");
        _;
    }

    modifier isWithdrawEnabled() {
        require(withdrawEnabled, "Withdraw not enabled");
        _;
    }
    
    constructor() {
        owner = 0xA281151C22a70d6743F5b31Bc4E3958ce3681985;
        fromTokenAddress = 0xaC94FDb161dADa96878e30c45A4b98b5929B24aC;
        toTokenAddress = 0x922e2708462c7a3d014D8344F7C4d92b27ECf332;

        _fromToken = IERC20(fromTokenAddress);
        _toToken = IERC20(toTokenAddress);
    }
    
    function status() public view returns (
            bool dEnabled,
            bool wEnabled,
            address fromToken,
            address toToken,
            uint256 balance,
            uint256 approved,
            uint256 owed,
            uint256 availableToken
        ) {
        dEnabled = depositEnabled;
        wEnabled = withdrawEnabled;
        fromToken = fromTokenAddress;
        toToken = toTokenAddress;
        balance = _fromToken.balanceOf(msg.sender);
        approved = _fromToken.allowance(msg.sender, address(this));
        owed = balances[msg.sender];
        availableToken = _toToken.balanceOf(address(this));
    }
    
    function deposit() external isDepositEnabled {
        uint256 amount = _fromToken.balanceOf(msg.sender);
        require(_fromToken.allowance(msg.sender, address(this)) >= amount, "Insufficient tokens approved");
        require(_fromToken.transferFrom(msg.sender, address(this), amount), "Unable to retrieve tokens");
        balances[msg.sender] += amount;
    }

    function withdraw() external isWithdrawEnabled {
        uint256 amount = balances[msg.sender];
        require(_toToken.transfer(msg.sender, amount), "Unable to exchange tokens");
        balances[msg.sender] = 0;
    }

    // Admin methods
    function setOwner(address who) external onlyOwner {
        require(who != address(0), "cannot be zero address");
        owner = who;
    }
    
    function setWithdrawEnabled(bool enable) external onlyOwner {
        withdrawEnabled = enable;
    }

    function setDepositEnabled(bool enable) external onlyOwner {
        depositEnabled = enable;
    }

    function setFromToken(address fromToken) external onlyOwner {
        fromTokenAddress = fromToken;
        _fromToken = IERC20(fromTokenAddress);
    }

    function setToToken(address toToken) external onlyOwner {
        toTokenAddress = toToken;
        _toToken = IERC20(toTokenAddress);
    }

    function removeEth() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }
    
    function removeTokens(address token) external onlyOwner returns(bool){
        uint256 balance = IERC20(token).balanceOf(address(this));
        return IERC20(token).transfer(owner, balance);
    }
}