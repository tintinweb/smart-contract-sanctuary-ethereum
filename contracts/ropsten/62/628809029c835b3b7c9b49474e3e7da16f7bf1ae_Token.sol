/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
interface ERC20Interface{
    // function totalSupply() external view returns(uint);
    // function balanceOf(address tokenOwner) external view returns(uint256 balance);
    // function allowance(address tokenOwner, address spender) external view returns(uint256 remaining);

    function transfer(address to, uint256 tokens) external returns(bool success);
    function approve(address _spender,uint256 _value )external returns(bool success);
    function transferFrom(address from, address to, uint256 _value) external returns(bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract Token is ERC20Interface{
    //state varibales

    string public name;//token name
    string public symbol;//token symbol
    uint public totalSupply;//token totalsupply
    uint public decimal;//token decimal

    mapping(address=>uint)public BalanceOf;
    mapping(address=>mapping(address=>uint256)) public Allownace;

    constructor(){
        name = "SampleToken";
        symbol = "SAT";
        totalSupply = 1000;
        decimal = 0;
        BalanceOf[msg.sender]=totalSupply;
    }

    function transfer(address _to, uint256 _value) public override returns(bool success){
        require(BalanceOf[msg.sender]>=_value);
        BalanceOf[msg.sender]-= _value;
        BalanceOf[_to]+=_value;

        emit Transfer(msg.sender,_to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public override returns(bool success){
        Allownace[msg.sender][_spender]=_value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns(bool success){
        require(_value<=BalanceOf[_from]);
        require(_value<= Allownace[_from][msg.sender]);

        Allownace[_from][msg.sender]-=_value;
        BalanceOf[_from]-= _value;
        BalanceOf[_to]+= _value;

        emit Transfer(_from,_to, _value);
        return true;
    }
}