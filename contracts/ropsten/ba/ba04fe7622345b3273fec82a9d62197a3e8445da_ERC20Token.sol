/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ERC20Interface{
    // function name() external view returns(string memory) ;
    // function symbol() external view returns(string memory);
    // function totalSupply() external view returns(uint256);
    // function balanceOf(address tokenOwner) external view returns(uint256);//to check balance of token owner.
    function approve(address spender,uint256 amount) external returns(bool success);
    function transfer(address to,uint256 tokens) external returns(bool success);
    function transferFrom(address transfer,address to, uint256 tokens) external returns(bool success);

    event Transfer(address indexed from,address indexed to,uint256 indexed value);
    event Approve(address indexed owner,address indexed spender,uint256 indexed value);
}
contract ERC20Token is ERC20Interface{
    string public name;
    string public symbol;
    uint256 public totalsupply;

    mapping(address => uint256) public balanceOf;//to check balance, this mapping is for balanceOf
    mapping(address => mapping(address => uint256)) public Allowance;//this mapping is for approve , i.e allowance

    constructor(uint256 initialSupply){
        totalsupply=initialSupply;
        name="KSS Tokens";
        symbol="KSST";
        balanceOf[msg.sender]=initialSupply;
    }
    function transfer(address to,uint256 value) public override returns(bool success){
        //1) condition will check owner ke paas sufficient balance hai kya transfer karne k liye
        require(balanceOf[msg.sender] >= value,"you dont have sufficient balance");
        balanceOf[msg.sender] -= value;//this will check amount deduct hua
        balanceOf[to] += value;//this will check amount credit hua
        emit Transfer(msg.sender,to,value);
        return true;
    }
    function approve(address spender,uint256 value) public override returns(bool success){
        Allowance[msg.sender][spender]=value;
        emit Approve(msg.sender,spender,value);
        return true;
    }//transfer from wahi use kar sakta hai jisko humne alow kiya hai hamare behalf me tokens send krne
    function transferFrom(address from, address to, uint256 value) public override returns(bool success){
        require(balanceOf[from]>=value,"do not have sufficient tokens");//Account should have enough balance to transfer.
        require(value<=Allowance[from][msg.sender],"don not have access to transfer");//check for approval
        Allowance[from][msg.sender]-=value;
        balanceOf[from]-=value;
        balanceOf[to]+=value;
        emit Transfer(from,to,value);
        return true;
    }

}