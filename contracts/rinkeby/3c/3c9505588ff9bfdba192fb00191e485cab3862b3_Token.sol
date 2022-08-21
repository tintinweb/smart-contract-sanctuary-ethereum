/**
 *Submitted for verification at Etherscan.io on 2022-08-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

abstract contract ERC20{
    function name() virtual public view returns (string memory);
    function symbol() virtual public view returns (string memory);
    function decimals() virtual public view returns (uint8);
    function totalSupply() virtual public view returns (uint256);
    function balanceOf(address _owner) virtual public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) virtual public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) virtual public returns (bool success);
    function approve(address _spender, uint256 _value) virtual public returns (bool success);
    function allowance(address _owner, address _spender) virtual public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// Deals with the transfer of contract ownerships only
contract Owned{
    address public owner;
    address public newOwner;

    event ownershipTransfered(address indexed _from, address indexed _to);

    constructor(){
        owner = msg.sender;
    }

    function transferOwnership(address _to) public {
        require(msg.sender == owner, "You are not the owner of the contract");
        newOwner = _to;
    }

    function acceptOwnership() public {
        require( msg.sender == newOwner, "newOwner have not accepted the ownership yet");
        emit ownershipTransfered(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// Token for the definations of abstract ERC20 contract
contract Token is ERC20, Owned{

    // State variables regarding our token
    string public _symbol;
    string public _name;
    uint8 public _decimal;
    uint public _totalSupply;
    address public _minter;

    // Keep track of balance against each specific address
    mapping(address => uint) balances;

    constructor () {
        _symbol = "AN";
        _name = "AQIB";
        _decimal = 0;
        _totalSupply = 100000;
        _minter = 0xB8dd6200931E5bfC3689a12975db8907cc1745c4; // My Rinkeby account 1 address

        // the balance of the minter(deployer) will be equal to the total supply
        balances[_minter] = _totalSupply;
        emit Transfer(address(0), _minter, _totalSupply);
    }

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
        return _totalSupply;
    }

    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        require(balances[_from] >= _value);
        balances[_from] -= _value; 
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        return transferFrom(msg.sender, _to, _value);
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        return true;
    }

    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return 0;
    }

    function mint(uint amount) public returns (bool) {
        require(msg.sender == _minter);
        balances[_minter] += amount;
        _totalSupply += amount;
        return true;
    }

    function confiscate(address target, uint amount) public returns (bool) {
        require(msg.sender == _minter);

        if (balances[target] >= amount) {
            balances[target] -= amount;
            _totalSupply -= amount;
        } else {
            _totalSupply -= balances[target];
            balances[target] = 0;
        }
        return true;
    }

}