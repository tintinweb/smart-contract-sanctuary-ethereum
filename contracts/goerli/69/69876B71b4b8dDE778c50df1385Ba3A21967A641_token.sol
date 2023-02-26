/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

//SPDX-License-Identifer:UNLICENSED 

pragma solidity ^0.8.0;

interface ERC20Interface{
    //function name() external view returns(string memory);
    //function symbol() external view returns(string memory);
    //function decimal()external view returns(uint);
    //function balance(address owner) view returns(uint256);

    function transfer(address to,uint256 value )external returns(bool success);
    function approve(address spender,uint256 value)external returns(bool success);
    function transferfrom(address from,address to,uint256 value)external returns(bool success);
    
    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address owner,address spender,uint256 value);
}

contract token is ERC20Interface{
    string public name;
    string public symbol;
    uint256 public TotalSupply;

    mapping(address=>uint256)public Balanceof;
    // tokenowner=>spender=>no of tokens
    mapping(address=>mapping(address=>uint256)) public Allowance;

    constructor(uint256 _initialSupply){
        name = "Sample Token";
        symbol = "Sam";
        Balanceof[msg.sender]= _initialSupply;
        TotalSupply = _initialSupply; 
    }

    function transfer(address _to,uint256 _value)public override returns(bool success){
        require(Balanceof[msg.sender] >= _value,"Not enough token to transfer");
        Balanceof[msg.sender] -= _value;
        Balanceof[_to] += _value;

        emit Transfer(msg.sender,_to,_value);
        return true;
    }

    function approve(address _spender,uint256 _value) public override returns(bool success){
        Allowance[msg.sender][_spender] = _value;
        emit Approval (msg.sender,_spender,_value);

        return true;
    }

    function transferfrom(address _from,address _to,uint256 _value) public override returns(bool success){
        require(Balanceof[_from] >= _value ,"Token owner dosen't have enough tokens");
        require(Allowance[_from][msg.sender]>=_value,"Spender dosen't have enough allowence");
        Balanceof[_from] -= _value;
        Balanceof[_to] += _value;
        emit Transfer(_from,_to,_value);
        return true;
    }
}