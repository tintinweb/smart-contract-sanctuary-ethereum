// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SybilToken {
    string private _name;
    string private _symbol;
    uint8 private constant _DECIMALS = 18;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _from, uint256 _value);

    constructor(string memory _tokenName, string memory _tokenSymbol, uint256 _initialSupply) {
        _name = _tokenName;
        _symbol = _tokenSymbol;
        _totalSupply = _initialSupply * 10 ** uint256(_DECIMALS);
        _balances[msg.sender] = _totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(
            _value <= _allowances[_from][msg.sender],
            "S20: Value exceeds the remaining allowance"
        );

        _allowances[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);

        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "S20: Cannot transfer tokens to address zero");
        require(_from != address(0), "S20: Cannot transfer tokens from address zero");
        require(_balances[_from] >= _value, "S20: Value exceeds the account balance");
        require(_balances[_to] + _value >= _balances[_to]);

        uint256 _previousBalances = _balances[_from] + _balances[_to];
        _balances[_from] -= _value;
        _balances[_to] += _value;

        emit Transfer(_from, _to, _value);
        assert(_balances[_from] + _balances[_to] == _previousBalances);
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(msg.sender != address(0), "S20: Cannot approve from address zero");
        require(_spender != address(0), "S20: Cannot approve address zero as spender");
        _allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(_balances[msg.sender] >= _value, "S20: Value exceeds the account balance");

        _totalSupply -= _value;
        _balances[msg.sender] -= _value;

        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(_from != address(0), "S20: Cannot burn tokens from address zero");
        require(_balances[_from] >= _value, "S20: Value exceeds the account balance");
        require(
            _value <= _allowances[_from][msg.sender],
            "S20: Value exceeds the remaining allowance"
        );

        _balances[_from] -= _value;
        _allowances[_from][msg.sender] -= _value;
        _totalSupply -= _value;

        emit Burn(_from, _value);
        return true;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _account) public view returns (uint256) {
        return _balances[_account];
    }

    function _allowance(address _owner, address _spender) public view returns (uint256) {
        return _allowances[_owner][_spender];
    }
}