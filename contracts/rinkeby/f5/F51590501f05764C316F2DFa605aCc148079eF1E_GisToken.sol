// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract GisToken {
    uint8 public constant decimals = 18;
    string public name;
    string public symbol;
    uint256 public totalSupply;
    address public owner;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(string memory _name, string memory _symbol){
        require(bytes(_name).length != 0 && bytes(_symbol).length != 0, "incorrect params.");
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "not an owner.");
        _;
    }

    modifier processable(address account, uint256 amount) {
        require(account != address(0), "account should not be the zero address.");
        require(amount != 0, "amount should not be zero.");
        _;
    }

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner, 
        address indexed _spender,
        uint256 _value
    );

    function balanceOf(address _owner) public view returns (uint256 balance){
        return _balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool){
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        require(allowance(_from, msg.sender) >= _value, "incorrect allowance.");
        _transfer(_from, _to, _value);

        _allowances[_from][msg.sender] -= _value;
        emit Approval(_from, msg.sender, _allowances[_from][msg.sender]);

        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) private {
        require(_to != address(0), "try to send tokens to the zero address.");
        require(_balances[_from] >= _value && 
                _balances[_to] + _value >= _balances[_to], "not enough tokens on sender balance or recipient balance overflow.");
        _balances[_from] -= _value;
        _balances[_to] += _value;

        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns(bool){
        require(_spender != address(0), "spender address should not be the zero address.");
        require(msg.sender != _spender, "owner and spender adresses are equal.");
        _allowances[msg.sender][_spender] = _value;
        return true;
    }

    function allowance(address _owner, address _spender) public view returns(uint256){
        require(_owner != address(0) && _spender != address(0), "incorrect address.");
        return _allowances[_owner][_spender];
    }

    function mint(address account, uint256 amount) onlyOwner processable(account, amount) public virtual {
        _balances[account] += amount;
        totalSupply += amount;
        emit Transfer(address(0), account, amount);
    }
    
    function burn(address account, uint256 amount) onlyOwner processable(account, amount) public virtual {
        require(_balances[account] >= amount, "burn amount larger than account balance.");
        _balances[account] -= amount;
        totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

}