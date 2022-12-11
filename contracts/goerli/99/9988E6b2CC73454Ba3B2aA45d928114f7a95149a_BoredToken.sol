/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

// contracts/BoredToken.sol
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract BoredToken {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public excludedFromFees;

    address private constant LiquidityProvider =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address private constant MarketingWallet =
        0x7943FB164289859b80f61050D571c8924A31eE9C;

    address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    uint256 public taxDivisor = 25;
    uint256 public limitDivisor = 50;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _decimals,
        uint256 _totalSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = totalSupply;

        excludedFromFees[msg.sender] = true;
        excludedFromFees[MarketingWallet] = true;
        excludedFromFees[LiquidityProvider] = true;
        excludedFromFees[address(this)] = true;
    }

    function transfer(address recipient, uint256 amount)
        external
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= amount);
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");

        if (excludedFromFees[sender] || excludedFromFees[recipient])
            _feelessTransfer(sender, recipient, amount);
        else {
            _taxedTransfer(sender, recipient, amount);
        }
    }

    function _taxedTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        uint256 recipientBalance = balanceOf[recipient];
        require(
            (recipientBalance + amount) <= totalSupply / limitDivisor,
            "Wallet contains more than 2% Total Supply"
        );

        uint256 taxFee = amount / taxDivisor;
        uint256 taxedAmount = amount - taxFee;

        balanceOf[sender] -= amount;
        balanceOf[recipient] += taxedAmount;
        balanceOf[MarketingWallet] += taxFee;
        emit Transfer(sender, recipient, taxedAmount);
    }

    function _feelessTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        uint256 senderBalance = balanceOf[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");

        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function approve(address recipient, uint256 amount)
        external
        returns (bool)
    {
        require(recipient != address(0));
        allowance[msg.sender][recipient] = amount;
        emit Approval(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        require(amount <= balanceOf[sender]);
        require(amount <= allowance[sender][msg.sender]);
        allowance[sender][msg.sender] =
            allowance[sender][msg.sender] -
            (amount);
        _transfer(sender, recipient, amount);
        return true;
    }
}