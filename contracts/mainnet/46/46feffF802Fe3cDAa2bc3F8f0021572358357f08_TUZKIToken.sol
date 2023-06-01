/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TUZKIToken is IERC20 {
    string public constant name = "Tuzki Inu";
    string public constant symbol = "\u5154\u65AF\u57FA\u72AC";
    uint8 public constant decimals = 18;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public owner;

    address private constant taxReceiver = 0xcc6F8E0F6C753463eCdb913CDC6f4bEeB827f3d0;
    
    uint256 public contractCreationTimestamp;
    uint256 public constant taxDuration = 30 minutes;

constructor() {
    uint256 initialSupply = 42069000000000 * (10 ** uint256(decimals)); // 42069 Billion
    _totalSupply = initialSupply;
    _balances[taxReceiver] = initialSupply;
    emit Transfer(address(0), taxReceiver, initialSupply);
    contractCreationTimestamp = block.timestamp;
    owner = address(0);
}

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address ownerAddress, address spender) public view override returns (uint256) {
        return _allowances[ownerAddress][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Insufficient allowance");
        _allowances[sender][msg.sender] = currentAllowance - amount;
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(_balances[sender] >= amount, "Insufficient balance");

        if (block.timestamp <= contractCreationTimestamp + taxDuration) {
            uint256 taxAmount = amount * 10 / 100;
            _balances[sender] -= taxAmount;
            _balances[taxReceiver] += taxAmount;
            emit Transfer(sender, taxReceiver, taxAmount);
            amount -= taxAmount;
        }

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
}