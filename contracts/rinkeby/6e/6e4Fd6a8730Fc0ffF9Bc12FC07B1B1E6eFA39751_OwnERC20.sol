// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OwnERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint private _totalSupply = 100_000 * (10 **  _decimals); //

    uint private _decimals = 18;
    string private _name = "IMISS";
    string private _symbol = "MSS";
    address owner;

    constructor() {
        owner = msg.sender;
        _balances[owner] = _totalSupply;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    modifier notAZeroAddress(address from, address to) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _;
    }
    
    function name() public view returns (string memory) {
        return _name;
    }

   
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address _owner) public view returns (uint256) {
        return _balances[_owner];
    }

    function transfer(address to, uint256 amount) public notAZeroAddress(msg.sender, to) returns (bool) {
        address _owner = msg.sender;
        _transfer(_owner, to, amount);
        return true;
    }

    function allowance(address _owner, address spender) public view returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public notAZeroAddress(msg.sender, spender) returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public notAZeroAddress(msg.sender, spender) returns (bool) {
        unchecked {
            _approve(msg.sender, spender, allowance(msg.sender, spender) + addedValue);
        }
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        require(allowance(msg.sender, spender) >= subtractedValue,
            "ERC20: decreased allowance below zero");

        unchecked {
            _approve(msg.sender, spender, allowance(msg.sender, spender) - subtractedValue);
        }
        return true;
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(owner == msg.sender, "Only owner can use this function");
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(uint _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address account, uint256 amount) internal {
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address _owner, address spender, uint256 amount) internal notAZeroAddress(_owner, spender) {
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal notAZeroAddress(from, to) {

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }


    function _spendAllowance(address _owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(_owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(_owner, spender, currentAllowance - amount);
            }
        }
    }
}