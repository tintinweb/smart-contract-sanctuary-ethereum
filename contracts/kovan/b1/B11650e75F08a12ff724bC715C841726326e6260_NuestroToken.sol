// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NuestroToken {
    
    // "private" makes it so that imports/inheritance cant alter variable
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    
    // Hash Tables / Dictionaries
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Logs/ Indexed max 3
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    constructor(string memory __name, string memory __symbol, uint8 __decimals) {
        _name = __name;
        _symbol = __symbol;
        _decimals = __decimals;
    }

    // memory is kind of like ram, only stored during function call
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _account) public view returns (uint256 balance) {
        return _balances[_account];
    }

    function _transfer(address _from, address _to, uint256 _amount) internal {
        // require reverts on failure
        // No one owns the zero address, when people use it, it is usally a software bug,
        // so it is an encouraged practice to revert when this is the case.
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        
        uint256 fromBalance = _balances[_from];
        require(fromBalance >= _amount, "ERC20: transfer amount exceeds balance");

        // Unchecked is used to avoid opcodes that run prior to the arithmeic
        // to check for under/overflow 
        // a.k.a "Saves gas"
        unchecked {
            _balances[_from] = fromBalance - _amount;
        }
        _balances[_to] += _amount;

        emit Transfer(_from, _to, _amount);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        address owner = msg.sender;
        _transfer(owner, _to, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return _allowances[_owner][_spender];
    }
    
    function _approve(address _owner, address _spender, uint256 _amount) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        address owner = msg.sender;
        _approve(owner, _spender, _value);
        return true;
    }
    
    function _spendAllowance(address _owner, address _spender, uint256 _value) internal {
        uint256 currentAllowance = allowance(_owner, _spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= _value, "ERC20: insufficient allowance");
            unchecked {
                _approve(_owner, _spender, currentAllowance - _value);
            }
        }
    } 

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        address spender = msg.sender;
        _spendAllowance(_from, spender, _value);
        _transfer(_from, _to, _value);
        return true;
    }

}