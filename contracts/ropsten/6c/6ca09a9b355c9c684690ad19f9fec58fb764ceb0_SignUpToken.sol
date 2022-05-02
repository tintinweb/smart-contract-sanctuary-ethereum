//SPDX-License-Identifer: MIT
pragma solidity ^0.8.7;

import './safemath.sol';

//ERC20 token standard
abstract contract ERC20Token {
    function name() public virtual view returns (string memory);
    function symbol() public virtual view returns (string memory);
    function decimals() public virtual view returns (uint8);
    function totalSupply() public virtual view returns (uint256);
    function balanceOf(address _owner) public virtual view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
    function allowance(address _owner, address _spender) public virtual view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


//Our token is a child class of ERC20Token
contract SignUpToken is ERC20Token {
    /*
    symbol: symbol of the token
    name: name of the token
    decimal: how many digits after '.'
    totalTokens: total token amount
    minter: the owner of this contract
    mapping is to record who own how many tokens
    */
    string public _symbol;
    string public _name;
    uint8 public _decimal;
    uint public _totalTokens;
    address public _minter;
    mapping(address => uint) balances;
    using SafeMath for uint256;

    //initialization
    constructor () {
        _symbol = "SUP";
        _name = "SignUpReward";
        _decimal = 3;
        _totalTokens = 100000;
        _minter = 0x5AE1bdAa34f594f97f4dfDA9eDbc6a7E532fc9bB;
        balances[_minter] = _totalTokens;

        //balance transfer should be recorded to the blockchain
        //therefore activate event
        emit Transfer(address(0), _minter, _totalTokens);
    }

    //Implement all other functions from ERC20Token
    function name() public override view returns (string memory) {
        return _name;
    }
    function symbol() public override view returns (string memory) {
        return _symbol;
    }
    function decimals() public override view returns (uint8) {
        return _decimal;
    }
    function totalSupply() public override view returns (uint256) {
        return _totalTokens;
    }
    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return balances[_owner];
    }

    /*
    transfer is where receiver website send token to the sender website who generate user for them
    First check if sender of this contract has enough token
    Second adjust the amount in there balance
    Last let blockchain record this action
    */

    // Allows the contract owner to give tokens to other users.
    function transfer(address to, uint256 tokens) public override returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    // This function is used to support automated transfers to a specific account.
    function transferFrom (address from, address to, uint256 tokens) public override returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        return true;
    }
    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return 0;
    }

    //only owner can mint token
    function mint(uint256 amount) public returns (bool) {
        require(msg.sender == _minter);
        balances[_minter] += amount;
        _totalTokens += amount;
        return true;
    }
}