//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";

contract ERCTOKEN {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    address private owner;

    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowances;

    string public name;
    string public symbol;
    uint public totalSupply;
    uint8 public decimals;

    constructor(
        string memory _name, 
        string memory _symbol, 
        uint8 _decimals
    ) {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    modifier isOnwer() {
        require(msg.sender == owner, "You are not an owner");
        _;
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
        _updateAllowance(_from, msg.sender, _value);
        _transfer(_from, _to, _value);
        return true;
    }

    function _updateAllowance(address _owner, address _spender, uint _value) internal {
        uint _allowance = allowance(_owner, _spender);
        require(_value <= _allowance, "Cannot spend out of allowance");
        _approve(_owner, _spender, _allowance - _value);
    }

    function _approve(address _owner, address _spender, uint _value) internal {
        require(_spender != address(0), "Cannot approve to the null address");

        allowances[_owner][_spender] = _value;

        emit Approval(_owner, _spender, _value);
    }

    function transfer(address _to, uint _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0), "Cannot transfer to the null address");
        require(_value <= balances[_from], "Cannot transfer out of balance");

        balances[_from] -= _value;
        balances[_to] += _value;

        emit Transfer(_from, _to, _value);
    }

    function mint(address _account, uint _amount) public isOnwer {
        require(_account != address(0), "Cant mint to zero address");
        totalSupply += _amount;
        balances[_account] += _amount;

        emit Transfer(address(0), _account, _amount);
    }

    function burn(address _account, uint _amount) public isOnwer {
        require(_account != address(0), "Cant burn from zero address");
        require(_amount <= balances[_account], "Amount out of balance");

        totalSupply -= _amount;
        balances[_account] -= _amount;

        emit Transfer(_account, address(0), _amount);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _value) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function mint(address _account, uint _amount) external;
    function burn(address _account, uint _amount) external;
}