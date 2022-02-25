//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

contract Token {
    address private _contractOwner;

    string private _name = "Token";
    string private _symbol = "TKN";
    uint8 private _decimals = 8;
    uint256 private _totalSupply = 10_000_000 * 10**_decimals;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() {
        _contractOwner = msg.sender;
        _balances[msg.sender] = _totalSupply;
    }

    modifier onlyOwner {
        require(msg.sender == _contractOwner, "Only owner can use this");
        _;
    }

    function _transfer(address _from, address _to, uint256 _value) private {
        require(_balances[_from] > _value, "Not enough tokens");
        emit Transfer(_from, _to, _value); // 0 values MUST be treated as normal transfers
        if (_balances[_to] + _value > _balances[_to]) {
            _balances[_from] -= _value;
            _balances[_to] += _value;
        }
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

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        emit Approval(msg.sender, _spender, _value);
        _allowances[msg.sender][_spender] = _value;
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_allowances[_from][_to] >= _value, "Not enough allowance");
        _transfer(_from, _to, _value);
        _allowances[_from][_to] -= _value;
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return _allowances[_owner][_spender];
    }

    function mint(address _to, uint256 _value) public onlyOwner {
        _totalSupply += _value;
        _balances[_to] += _value;
    }

    function burn(address _from, uint256 value) public onlyOwner {
        require(_totalSupply >= value, "Invalid value");
        require(_balances[_from] >= value, "Invalid value");
        _totalSupply -= value;
        _balances[_from] -= value;
    }
}