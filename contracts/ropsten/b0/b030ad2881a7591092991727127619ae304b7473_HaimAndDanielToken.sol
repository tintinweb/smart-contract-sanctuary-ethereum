/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

pragma solidity ^0.8.6;

// SPDX-License-Identifier: MIT

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
abstract contract ERC20Token {
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

// ----------------------------------------------------------------------------
// The token contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address _to) public {
        require(msg.sender == owner);
        newOwner = _to;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract HaimAndDanielToken is ERC20Token, Owned {
    string public _symbol;
    string public _name;
    uint8 public _decimal;
    uint public _totalSupply;
    address public _minter;

    // This mapping is where we store the balances of an address
    mapping(address => uint) balances;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor () {
        _symbol = "HAD";
        _name = "Haim And Daniel Token";
        _decimal = 18;
        //1,000,000 + 18 zeros
        _totalSupply = 1000000000000000000000000;
        _minter = 0xF1e0bdf94FB53f84B65E493c574434F7B01e50fB;

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

    // Constant value that does not change
    // returns the amount of initial tokens to display
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    // Returns the balance of a specific address
    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return balances[_owner];
    }

    // This allows someone else (a 3rd party) to transfer from my wallet to someone elses wallet
    // Perform the transfer by increasing the to account, and decreasing the "_from" account
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        require(balances[_from] >= _value);
        balances[_from] -= _value; // balances[_from] = balances[_from] - _value
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    // Transfer an amount of tokens to another address
    // Decrease the balance of the sender, and increase the balance of the "_to" address
    function transfer(address _to, uint256 _value) public override returns (bool success) {
        return transferFrom(msg.sender, _to, _value);
    }

    // Allows a spender address to spend a specific amount of tokens
    function approve(address _spender, uint256 _value) public override returns (bool success) {
        return true;
    }

    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return 0;
    }
}