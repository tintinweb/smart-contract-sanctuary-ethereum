/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

//SPDX-License-Identifier: Unlincecsed

pragma solidity ^0.8.0;

interface ERC20Interface{
    // function name() external view returns(string memory);
    // function symbol external view returns(string memory);
    // function totalSupply() external view returns(uint);
    // function balanceOf(address tokenowner) external view returns(uint256 balance);
    function approve(address spender,uint256 amount) external returns(bool success);
    function transfer(address to, uint256 tokens) external returns(bool success);
    function transferFrom(address transfer, address to, uint256 tokens) external returns(bool success);

    event Transfer(address indexed from, address indexed to, uint256 indexed value);
    event Approve(address indexed owner, address indexed spender, uint256 indexed value);
}
contract ERC20Token is ERC20Interface{
    //state variables
    string public name;//token name
    string public symbol;//token symbol
    uint256 public TotalSupply;//token supply

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address=>uint256)) public Allowance;

    //constructor
    constructor(uint256 initialsupply){
        TotalSupply = initialsupply;
        name= "IBI Token";
        symbol="IBI";
        balanceOf[msg.sender]= initialsupply;
    }
    function transfer(address to, uint256 value) public override returns(bool success){
        //Account should have enough tokens
        require(balanceOf[msg.sender]>=value,"You do not have enough Tokens to Transfer");
        balanceOf[msg.sender]-=value;
        balanceOf[to]+=value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    function approve(address spender, uint256 value) public override returns(bool success){
        Allowance[msg.sender][spender]=value;
        emit Approve(msg.sender,spender,value);
        return true;
    }
    function transferFrom(address from, address to, uint256 value) public override returns(bool success){
        require(balanceOf[from]>=value,"sender do not have enough tokens to transfer");//account should have enough tokens
        require(Allowance[from][msg.sender]>=value);//check for approval
        Allowance[from][msg.sender]-= value;
        balanceOf[from]-=value;
        balanceOf[to]+=value;
        emit Transfer(from, to, value);
        return true;
    }






}