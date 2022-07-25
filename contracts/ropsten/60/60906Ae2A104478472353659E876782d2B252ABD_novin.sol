/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract novin {
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowance;
    address owner;
    uint256 _totalSupply;
    string _name;
    string _symbol;
    uint8 _decimal;

    event Transfer(address from, address to, uint256 amount);
    event Approval(address owner, address spender, uint256 amount);

    constructor() {
        owner = msg.sender;
        _name = "novin";
        _symbol = "nvn";
        _decimal = 18;
        _totalSupply = 100 * (10**_decimal);
        _balances[owner] = _totalSupply;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimal;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balances[_owner];
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_balances[_from] >= _value);
        _balances[_from] -= _value;
        _balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        return transferFrom(msg.sender, _to, _value);
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {}

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return _allowance[_owner][_spender];
    }
}