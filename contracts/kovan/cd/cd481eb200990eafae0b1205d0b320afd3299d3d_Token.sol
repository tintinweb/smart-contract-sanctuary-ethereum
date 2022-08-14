/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

// SPDX-License-Identifier: UNLICENSED
// File: contracts/ERC20_tokken.sol


pragma solidity ^0.8.7;

// ERC20 Interface.
interface ERC20interface{
    
    // cause we are using state variables as public we get inbuild getter for them.

    // function name()external view returns(string memory);                  
    // function symbol()external view returns(string memory);
    // function decimal()external view returns(uint);          // a number in which token can be divisible into.
    // function balance_of(address owner) view returns(uint256);  // balance of address owner.

    function function_transfer(address _to, uint256 _value)external returns(bool success); // transfer token to address. if success return bool.
    function function_approve(address _spender, uint256 _value)external returns(bool success); // assign spender no. of token allowed to spend.
    function transfer_from(address _from, address _to, uint256 _value)external returns(bool success); // transfer from one address to another.

    event event_transfer(address indexed _from, address indexed _to, uint256 _value); // 
    event event_approval(address _owner, address _spender, uint256 _value); // 
}

// Contract ERC20 TOKEN.
contract Token is ERC20interface{

    // state variables.
    string public name;
    string public symbol;
    uint256 public total_supply;

    mapping(address=>uint256) public balance_of ;
    mapping(address=>mapping(address=>uint256)) public allowance ;
    // token owner => spender => no. of tokens.

    // constructor.
    constructor(uint256 _initial_supply){
        name = "sample_token" ;
        symbol = "SAM" ;
        balance_of[msg.sender] = _initial_supply ;
        total_supply = _initial_supply ;
    }
    
    // functions.
    // name 

    // symbol.

    // decimal.

    // balance_of.

    // function_transfer.
    function function_transfer(address _to, uint256 _value)public override returns(bool success){
        require(balance_of[msg.sender]>= _value , "not enough tokens to transfer ");
        balance_of[msg.sender] -= _value;
        balance_of[_to] += _value ;

        emit event_transfer(msg.sender, _to, _value);
        return true ;
    }

    // function_approval
    function function_approve(address _spender, uint256 _value)public override returns(bool succcess){
        allowance[msg.sender][_spender] = _value ;   // update allowance mapping.

        emit event_approval(msg.sender, _spender, _value);
        return true ;

    }

    // function transfer_from.
    function transfer_from(address _from, address _to ,uint256 _value)public override returns(bool success){
        require(balance_of[_from] >= _value, "token owner doesn't have enough tokens ");
        require(allowance[_from][msg.sender] >= _value, " spender doesn't have enough allowance ");
        balance_of[_from] -= _value ;
        balance_of[_to] += _value;

        emit event_transfer(_from , _to, _value);
        return success ;
    }
}