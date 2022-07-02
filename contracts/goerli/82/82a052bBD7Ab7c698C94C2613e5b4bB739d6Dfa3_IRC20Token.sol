pragma solidity ^0.7.0;

contract IRC20Token{

    string private constant name_ = "IRC20Token";
    string private constant symbol_ = "IRC";
    uint8 private constant decimals_ = 8;
    uint256 private totalSupply_;
    address private minter_;


    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;


    event Transfer(address indexed _from, address indexed _spender, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(uint256 _totalSupplyInitial) {
        minter_ = msg.sender;
        mint(minter_, _totalSupplyInitial);
    }

    function name() public pure returns (string memory) {
        return name_;
    }

    function symbol() public pure returns (string memory) {
        return symbol_;
    }

    function decimals() public pure returns (uint8) {
        return decimals_;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool succes) {
        require(_value <= _balances[msg.sender]);
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool succes) {
        require(_value <= allowance(_from, _to) && _value <= balanceOf(_from));
        _balances[_from] -= _value;
        _allowances[_from][_to] -= _value;
        _balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns(uint256 remaining) {
        return _allowances[_owner][_spender];
    }

    function burn(address _owner, uint256 _value) public {
        require(msg.sender == minter_);
        require(_value <= balanceOf(_owner ));
        _balances[_owner] -= _value;
        totalSupply_ -= _value;
    }

    function mint(address _owner, uint256 _value) public {
        require(msg.sender == minter_);
        _balances[_owner] += _value;
        totalSupply_ += _value;
    }

}