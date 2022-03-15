/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

//SPDX-License-Identifier:UNLICENSED

pragma solidity ^0.8.0;

//ERC20 Interface
interface ERC20Interface{
    // function name() external view returns(string memory);
    // function symbol() external view returns(string memory);
    // function decimal() external view returns(uint);
    // function balanceOf(address owner) view returns(uint256);

    function transfer(address to, uint256 value) external returns(bool success);
    function approve(address spender, uint256 value) external returns(bool success);
    function transferFrom(address from, address to, uint256 value) external returns(bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address owner, address spender, uint256 value);
}

//Contract ERC20 token
contract Token is ERC20Interface{
    //state variables
    string public name;
    string public symbol;
    uint256 public TotalSupply;

    mapping(address=>uint256) public BalanceOf;
           //tokenowner=>spender=>no of tokens  
    mapping(address=>mapping(address=>uint256)) public Allowance;

    //constructor
    constructor(uint256 _initialSupply){
        name = "Sampletoken"; //name token
        symbol = "SAM";       //symbol token
        BalanceOf[msg.sender] = _initialSupply; 
        TotalSupply = _initialSupply;
    }
    //name function
    //symbol function
    //decimal function
    //balanceOf functon

    //transfer function
    function transfer(address _to, uint256 _value) public override returns(bool success){
        //if account has tokens enough to be transfered
        require(BalanceOf[msg.sender] >= _value,"Not Enough Tokens To Transfer");
        //transfer
        BalanceOf[msg.sender]-=_value;
        BalanceOf[_to] += _value;
        //transfer event
        emit Transfer(msg.sender,_to,_value);
        return true;
    }
    //approve function
    function approve(address _spender, uint256 _value) public override returns(bool success){
        //update Allowance mapping
        Allowance[msg.sender][_spender] = _value;
        //emit Approve event
        emit Approval(msg.sender,_spender,_value);

        //return
        return true;
    }

    //transferfrom function
    function transferFrom(address _from, address _to, uint256 _value) public override returns(bool success){
    //requirment from address have enough tokens
    require(BalanceOf[_from]>=_value,"Token Owner Doesn't Have Enough Tokens");
    //allownace is big enough to tranfer
    require(Allowance[_from][msg.sender]>= _value,"Spender Doesn't Have Enough Allownace");
    //tranfer
    BalanceOf[_from] -= _value;
    BalanceOf[_to] += _value;
    //emit transfer event
    emit Transfer(_from, _to, _value);
    //return
    return true;
    }
}