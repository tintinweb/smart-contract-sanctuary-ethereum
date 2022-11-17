/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract ERC20Reward {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    string private tokenName;
    string private tokenSymbol;
    uint256 private tokenSupply;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    constructor() {
        tokenName = "Reward";
        tokenSymbol = "RT";
        tokenSupply = 100000000 * (10**decimals());
        balances[msg.sender] = tokenSupply;
    }

    modifier isAddrNull(address _address) {
        require(_address != address(0), "Address null");
        _;
    }

    function name() public view returns (string memory) {
         return tokenName;
    }

    function symbol() public view returns (string memory) {
        return tokenSymbol;
    }

    function decimals() public pure  returns (uint256) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return tokenSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public isAddrNull(_to) returns (bool success) {
        require(_value <= balances[msg.sender] && _value > 0, "Not enough tokens");
        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external isAddrNull(_from) isAddrNull(_to) returns (bool success) {
        require (_value > 0 && _value <= allowances[_from][msg.sender] && balanceOf(_from) >= _value, "Not enough tokens allowed");
        balances[_from] -= _value;
        allowances[_from][msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public isAddrNull(_spender) returns (bool success) {
        require(_value > 0 && _value <= balances[msg.sender], "Not enough tokens");
        allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }
}