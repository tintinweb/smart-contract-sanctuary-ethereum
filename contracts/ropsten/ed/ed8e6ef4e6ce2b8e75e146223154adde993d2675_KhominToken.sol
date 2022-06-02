/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

pragma solidity >=0.7.0 < 0.9.0;

contract KhominToken {

    uint256 public _totalSupply;
    uint256 public _inUse;
    uint public _maxBalance = 500;
    string public _name = "Khomin Token";
    string public _symbol = "KHTK";
    uint8 public _decimals = 2;

    mapping(address => uint) public _balances;
    mapping(address => mapping(address => uint)) public _allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 value);

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

    function transfer(address _to, uint256 _value) public payable returns (bool success) {
        require(_balances[_to] + _value <= _maxBalance, 'Too many tokens');
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public payable returns (bool success) {
        require(_balances[_to] + _value <= _maxBalance, 'Too many tokens');
        _allowance[_from][msg.sender] -= _value;
        _balances[_from] -= _value;
        _balances[_to] += _value;
        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return _allowance[_owner][_spender];
    }

    function deposit() external payable {
        require(_balances[msg.sender] + msg.value * 100 <= _maxBalance, 'Too many tokens');
        require(_inUse + msg.value * 100 <= _totalSupply, 'Not enough tokens');

        _balances[msg.sender] += msg.value * 100;
        _inUse += msg.value * 100;
    }

    constructor(uint __totalSupply, uint __maxBalance) public {
        _totalSupply = __totalSupply;
        _maxBalance = __maxBalance;
    }

}