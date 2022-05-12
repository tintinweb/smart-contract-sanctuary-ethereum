//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract ERC {

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    address private owner;

    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowances;

    string public _name;  // = "Cryptocurrency Rescue Token";
    string public _symbol;  // = "CRT";
    uint public _totalSupply;  // = 1000000000000000000000000000
    uint8 public _decimals;  // = 18;

    constructor(
        string memory _iName, 
        string memory _iSymbol, 
        uint _iTotalSupply,
        uint8 _iDecimals
    ) {
        owner = msg.sender;
        _name = _iName;
        _symbol = _iSymbol;
        _totalSupply = _iTotalSupply;
        _decimals = _iDecimals;
    }

    modifier isOnwer() {
        require(msg.sender == owner, "You are not an owner");
        _;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function balanceOf(address _owner) public view returns (uint) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint _value) public returns (bool) {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(_from != address(0), "Cannot transfer from the null address");
        _approve(_from, msg.sender, _value);
        _transfer(_from, _to, _value);
        return true;
    }

    function updateAllowance(address _owner, address _spender, uint _value) internal {
        uint _allowance = allowance(_owner, _spender);
        require(_value <= _allowance, "cannot spend > allowance");
        _approve(_owner, _spender, _allowance - _value);
    }

    function _approve(address _owner, address _spender, uint _value) internal {
        allowances[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
    }

    function transfer(address _to, uint _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0), "Cannot transfer to the null address");
        require(_value <= balances[_from], "Value > balance");

        balances[_from] -= _value;
        balances[_to] += _value;

        emit Transfer(_from, _to, _value);
    }

    function mint(address _account, uint _amount) public isOnwer {
        require(_account != address(0), "zero address");
        _totalSupply += _amount;
        balances[_account] += _amount;

        emit Transfer(address(0), _account, _amount);
    }

    function burn(address _account, uint _amount) public isOnwer {
        require(_account != address(0), "zero address");
        require(_amount <= balances[_account], "amount > balance");

        _totalSupply -= _amount;
        balances[_account] -= _amount;

        emit Transfer(_account, address(0), _amount);
    }
}