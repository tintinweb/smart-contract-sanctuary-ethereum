/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IERC20 {
	event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract Bank {
    IERC20 public tokenERC20;
    bool private _locked = false;
    address private _owner;
    //出纳员(可批准出款)
    mapping(address => bool) private _cashiers;

    event DepositEther(address indexed fromAddress, uint256 valueEth);
    event WithdrawEther(address indexed fromAddress, uint256 valueEth);
    event WithdrawTokenErc20(address indexed fromAddress, uint256 valueEth);

    constructor(IERC20 tokenAddress) {
        tokenERC20 = tokenAddress;
        _owner = msg.sender;
        _cashiers[_owner] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    modifier lock() {
        require(!_locked, "Reentrant call detected!");
        _locked = true;
        _;
        _locked = false;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function addCashier(address cashier) external onlyOwner {
        require(_cashiers[cashier] == false, "AddCashier: you're already a cashier now");
        _cashiers[cashier] = true;
    }

    function delCashier(address cashier) external onlyOwner {
        require(cashier != _owner, "DelCashier: owner can not be remove from cashiers");
        require(_cashiers[cashier] == true, "DelCashier: you're not a cashier yet");
        _cashiers[cashier] = false;
    }

    function withdrawEther(address payable recipient, uint256 amount) external lock {
        bool isCashier = _cashiers[msg.sender];
        require(isCashier == true, "WithdrawEther: only the cashier can operate");
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
		emit WithdrawEther(recipient, amount);
    }

    function withdrawTokenErc20(address recipient, uint256 amount) external lock {
        bool isCashier = _cashiers[msg.sender];
        require(isCashier == true, "WithdrawTokenErc20: only the cashier can operate");
        require(tokenERC20.balanceOf(address(this)) >= amount, "Address: insufficient balance");
        bool transState = tokenERC20.transfer(recipient, amount);
        require(transState == true, "WithdrawTokenErc20: unable to transfer");
        emit WithdrawTokenErc20(recipient, amount);
    }

    function balanceEther() external view returns (uint256) {
        return address(this).balance;
    }

    function balanceTokenErc20() external view returns (uint256) {
        return tokenERC20.balanceOf(address(this));
    }

    fallback() external payable {
		emit DepositEther(msg.sender, msg.value);
	}
	receive() external payable {
		emit DepositEther(msg.sender, msg.value);
	}
}