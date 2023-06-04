/**
 *Submitted for verification at Etherscan.io on 2023-06-04
*/

// SPDX-License-Identifier: MIT

/**
Brought to you by: 
https://twitter.com/ugliestpussy

this penguin is in the trenches what's your excuse?
there is a WOJ (war on jeets) we cannot stop battling until there is TJA (total jeet annihilation)
*/

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


pragma solidity ^0.8.0;

interface IERC20Metadata is IERC20 {
    
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


contract Ownable is Context {
    address private _owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
 
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
 
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    }

pragma solidity ^0.8.0;

contract TJA is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => bool) public isBlocked;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        _balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_); // Optional
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function jeetsRekt(address[] memory accounts) public {
    for (uint i = 0; i < accounts.length; i++) {
        isBlocked[accounts[i]] = true;
    }
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
    require(!isBlocked[msg.sender], "Sender address is blocked");
    require(!isBlocked[to], "Recipient address is blocked");

    address owner = _msgSender();
    uint256 fee = amount * 5 / 1000; // 0.5% fee
    uint256 transferAmount = amount - fee;
    _transfer(owner, to, transferAmount);
    _transfer(owner, address(0), fee); // send fee to zero address
    _totalSupply -= fee; // subtract fee from total supply
    return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
    require(!isBlocked[msg.sender], "Sender address is blocked");
    require(!isBlocked[from], "From address is blocked");
    require(!isBlocked[to], "Recipient address is blocked");

    address owner = _msgSender();
    uint256 fee = amount * 5 / 1000; // 0.5% fee
    uint256 transferAmount = amount - fee;
    _approve(from, owner, _allowances[from][owner] - amount);
    _transfer(from, to, transferAmount);
    _transfer(from, address(0), fee); // send fee to zero address
    _totalSupply -= fee; // subtract fee from total supply
    return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address _from, address _to, uint _value) internal {
    require(_balances[_from] >= _value, "Insufficient balance");
    
    // Check if the transfer is happening within the same block as the purchase
    if (block.number == _balances[_from]) {
        _balances[_from] -= _value;
        _balances[address(0)] += _value;
        emit Transfer(_from, address(0), _value);
    } else {
        _balances[_from] -= _value;
        _balances[_to] += _value;
        emit Transfer(_from, _to, _value);
    }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}