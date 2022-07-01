// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

interface ERC20 {
    function totalSupply() external view returns (uint _totalSupply);

    function balanceOf(address _owner) external view returns (uint balance);

    function transfer(address _to, uint _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint _value) external returns (bool success);

    function approve(address _spender, uint _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

}

contract ZuzuToken is ERC20 {

    string public constant symbol = "Z"; //symbol of our token
    string public constant name = "Zuzu"; //name of our token

    //Since solidity does not support decimal numbers so,  
    //Minting or transferring tokens may require number in decimals, (eg: 15.3Z)
    //ERC-20 uses 20 value for decimal
    //{token*10^(decimal)}
    uint8 public constant decimals = 18; 

    uint private constant _totalSupply = 1000000000000000000000000; //Tokens available in our contract

    //address refers to the balance
    mapping (address => uint) private _balanceOf;

    //nested mapping, how much an address can spend used for approval function, (number of tokens that can be transferred)
    mapping (address => mapping (address => uint)) private _allowances;

    constructor() public {
        _balanceOf[msg.sender] = _totalSupply; //balance of deploying adress = total tokens
    }

    //Returns total tokens 
    function totalSupply() public pure returns (uint256) {
      return _totalSupply; 
    }

    //Returns balance of a given address
    function balanceOf(address _addr) public view override returns (uint) {
        return _balanceOf[_addr];
    }

    //Returns a set amount of tokens from a spender to the owner
    function allowance(address _owner, address _spender) external override view returns (uint remaining) {
        return _allowances[_owner][_spender];
    }

    //Transfer amount of token from one account to another specified address
    function transfer(address _to, uint _value) public override returns (bool success) {
        
        //Amount of tokens to be transfered should be greater than 0 and less than total tokens in account
        if (_value > 0 && _value <= balanceOf(msg.sender)) { 
            _balanceOf[msg.sender] -= _value; //subtract amount of tokens transfered from sender
            _balanceOf[_to] += _value; //add amount of tokens transferred to receiver 
            emit Transfer(msg.sender, _to, _value); //emits event
            return true;
        }
        return false;
    }

    //3rd party - Anyone can transfer amount from account to another account
    function transferFrom(address _from, address _to, uint _value) public override returns (bool success) {
        
        require(_value <= _balanceOf[_from], "Account does not have entered amount of tokens"); 
        require(_value <= _allowances[_from][msg.sender], "Not approved to send this amount of tokens");   
        _balanceOf[_from] -= _value; //subtract amount of tokens transfered from sender
        _allowances[_from][msg.sender] -= _value; //subract amount of tokens allowed to spend
        _balanceOf[_to] += _value; //add amount of tokens transferred to receiver
        emit Transfer(_from, _to, _value); //emits event
        return true;
    }

    //Allow a spender to withdraw a set number of tokens from a specified account
    function approve(address _spender, uint _value) external override returns (bool success) {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}