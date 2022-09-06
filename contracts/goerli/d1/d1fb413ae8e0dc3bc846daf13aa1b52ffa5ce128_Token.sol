/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor () {
        owner = msg.sender;
    }

    function transferOwnership(address _to) public {
        require(msg.sender == owner);
        newOwner = _to;
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

/// @title RugPool Token

contract Token is Owned {

    string public _symbol;
    string public _name;
    uint8 public _decimals;
    uint public _totalSupply;
    address public _minter;

    // Keep track of balances and allowances approved
    mapping(address => uint) public balances;
    mapping(address => mapping(address =>uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor () {
        _symbol = "GBP";
        _name = "RugPool";
        _decimals = 18;
        _totalSupply = 2000000000000000000000000; // 2 million tokens
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), _minter, _totalSupply);
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
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /// @dev internal helper transfer function with required safety checks
    /// Internal function transfer can be only called from this contract
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        balances[_from] = balances[_from] - (_value);
        balances[_to] = balances[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }

    /// @notice Approve others to spend on _spenders behalf, for instance, an exchange
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @notice transfer by approved person from original address of an amount
    /// @dev internal helper transfer function with required safety checks
    /// Allow _spender to spend on _froms behalf
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
            require(_value <= balances[_from]);
            require(_value <= allowance[_from][msg.sender]);
            allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
            _transfer(_from, _to, _value);
            return true;
    }

    function mint(uint amount) public returns (bool) {
        require(msg.sender == _minter);
        balances[_minter] += amount;
        _totalSupply += amount;
        return true;
    }

}