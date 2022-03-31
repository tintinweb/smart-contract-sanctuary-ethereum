/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

//SPDX-License-Identifier: Unlincecsed
pragma solidity ^0.8.0;

interface ERC20interface{
    // function name() external view returns(string memory);
    // function symbol() external view returns(string memory);
    // function totalSupply() external view returns(uint256);
    // function balanceOf(address tokenOwner) external view returns(uint256 balance);
    function approve(address spender,uint amount) external returns(bool success);
    function transfer(address to,uint256 tokens) external returns(bool success);
    function transferFrom(address transfer,address to,uint256 tokens) external returns(bool success);

    event Transfer(address indexed from, address indexed to,uint256 indexed value);
    event Approve(address indexed owner,address indexed spender,uint256 indexed value); 
}
contract ERC20Token is ERC20interface{
    //state variables
    string public name;
    string public symbol;
    uint256 public TotalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public Allowance;

    constructor(uint256 initialSupply){
        TotalSupply =initialSupply;
        name = "Vick";
        symbol="VK";
        balanceOf[msg.sender] = initialSupply;
    }
    function transfer(address to,uint256 value) public override returns(bool success){
        //account should have enough balance
        require(balanceOf[msg.sender]>=value,"you dont have enough tokens to transfer");
        balanceOf[msg.sender]-=value;
        balanceOf[to]+=value;
        emit Transfer(msg.sender,to,value);
        return true;
    }
    function approve(address spender,uint256 value) public override returns(bool success){
        Allowance[msg.sender][spender] = value;
        emit Approve(msg.sender,spender, value);
        return true;
    }
    function transferFrom(address from,address to,uint256 value) public override returns(bool success){
        require(balanceOf[from]>=value,"sender do not have enough tokens to transfer");
        require(value <= Allowance[from][msg.sender]);
        Allowance[from][msg.sender]-=value;
        balanceOf[from]-=value;
        balanceOf[to]+=value;
        emit Transfer(from, to , value);
        return true;

    }

}