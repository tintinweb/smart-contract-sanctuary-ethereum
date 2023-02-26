// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract smsv2 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed to, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(
        address _owner,
        address _spender
    ) public view returns (uint256 remaining) {
        return _allowances[_owner][_spender];
    }

    function mint(address _to, uint256 _amount) public returns (bool) {
        // require(msg.sender == owner);
        _totalSupply += _amount;
        _balances[_to] += _amount;
        emit Mint(_to, _amount);
        return true;
    }

    function burn(address _to, uint256 _amount) public returns (bool) {
        // require(msg.sender == owner);
        require(_balances[_to] >= _amount, "Not Enough Balance To Burn");
        _totalSupply -= _amount;
        _balances[_to] -= _amount;
        emit Burn(_to, _amount);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= _balances[msg.sender]);
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(_to != address(0), "Invalid Sender Address");
        require(_value <= _balances[_from], "Not enough Balance ");
        require(
            _value <= _allowances[_from][msg.sender],
            "Allowanced Balance is Lower"
        );
        _balances[_from] -= _value;
        _balances[_to] += _value;
        _allowances[_from][msg.sender] =
            _allowances[_from][msg.sender] -
            (_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
}