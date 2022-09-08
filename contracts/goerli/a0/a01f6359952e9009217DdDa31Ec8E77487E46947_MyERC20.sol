/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

/**
 *Submitted for verification at BscScan.com on 2022-08-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library Roles {
    struct Role {
        mapping(address => bool) bearer;
        // mapping(address => uint256) bearerIndex;
        // address[] addressList;
    }

    function add(Role storage role, address account) internal {
        require(account != address(0), "Roles: account is zero address");
        require(!has(role, account), "Roles: account has role");

        role.bearer[account] = true;
        // role.bearerIndex[account] = role.addressList.length;
        // role.addressList.push(account);
    }

    function remove(Role storage role, address account) internal {
        require(account != address(0), "Roles: account is zero address");
        require(has(role, account), "Roles: account does not have role");

        role.bearer[account] = false;
        // role.addressList[role.bearerIndex[account]] = role.addressList[
        //     role.addressList.length - 1
        // ];
        // role.bearerIndex[role.addressList[role.bearerIndex[account]]] = role.bearerIndex[account];
        // role.addressList.pop();
    }

    // function getAddressList(Role storage role)
    //     internal
    //     view
    //     returns (address[] memory)
    // {
    //     return role.addressList;
    // }

    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is zero address");
        return role.bearer[account];
    }
}

contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address private _owner;

    constructor() {
        _transferOwnership(msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: newOwner is zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor() {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller is not minter");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    // function minters() public view returns (address[] memory) {
    //     return _minters.getAddressList();
    // }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

contract Lockable is Ownable {
    bool private _lockedContract;
    mapping(address => bool) private _userBlocks;

    constructor() {
        _lockedContract = false;
    }

    modifier onlyUnLocked(
        address sender,
        address from,
        address to
    ) {
        require(!isLockedContract(), "Auth: Contract is locked");
        bool isLocked = isLockedUser(sender) || isLockedUser(from) || isLockedUser(to);
        require(!isLocked, "Auth: User is locked");
        _;
    }

    function userBlocks(address account) public view returns (bool) {
        return _userBlocks[account];
    }

    function isLockedUser(address account) public view returns (bool) {
        return _userBlocks[account];
    }

    function isLockedContract() public view returns (bool) {
        return _lockedContract;
    }

    function toggleLock() public onlyOwner {
        _lockedContract = !_lockedContract;
    }

    function setBlockUser(address account, bool status) public onlyOwner {
        _userBlocks[account] = status;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transfer(address to, uint256 value) public virtual returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual returns (bool) {
        require(value <= _allowances[from][msg.sender], "ERC20: transfer amount exceeds allowance");

        _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);
        _transfer(from, to, value);

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(value <= _balances[from], "ERC20: transfer amount exceeds balance");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);

        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(value <= _balances[account], "ERC20: burn amount exceeds balance");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
}

contract MyERC20 is ERC20, MinterRole, Lockable {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function transfer(address to, uint256 value) public override onlyUnLocked(msg.sender, msg.sender, to) returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override onlyUnLocked(msg.sender, from, to) returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }

    function burn(uint256 value) public returns (bool) {
        _burn(msg.sender, value);
        return true;
    }
}