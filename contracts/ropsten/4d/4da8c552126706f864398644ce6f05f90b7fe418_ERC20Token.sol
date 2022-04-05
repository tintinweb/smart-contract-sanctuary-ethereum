/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

//SPDX-License-Identifier: Unlincecsed
pragma solidity ^0.8.0;

interface ERC20interface{
    function Name() external view returns(string memory);
    function Symbol() external view returns(string memory);
    function totalSupply() external view returns(uint256);
    function balanceOf(address TokenOwner) external view returns(uint256 balance);
    function approve(address spender,uint amount) external returns(bool success);
    function transfer(address to,uint256 tokens) external returns(bool success);
    function transferFrom(address transfer,address to,uint256 tokens) external returns(bool success);

    event Transfer(address indexed from, address indexed to,uint256 indexed value);
    event Approve(address indexed owner,address indexed spender,uint256 indexed value); 
}
contract ERC20Token is ERC20interface{
    //state variables
    string private name;
    string private symbol;
    uint256 private TotalSupply;

    mapping(address => uint256) public balanceof;
    mapping(address => mapping(address => uint256)) public Allowance;

    constructor(uint256 initialSupply,string memory Tname,string memory symbolT){
        TotalSupply =initialSupply;
        name = Tname;
        symbol= symbolT;
        balanceof[msg.sender] = initialSupply;
    }
    function Name() external  view override returns(string memory) {
        return name;
    } 
    function Symbol() external view override returns(string memory){
        return symbol;
    }
    function totalSupply() external view override returns(uint){
        return TotalSupply;
    }
    function balanceOf(address _Owner) external view override returns(uint256){
        return balanceof[_Owner];
    }
    function transfer(address to,uint256 value) public override returns(bool success){
        //account should have enough balance
        require(balanceof[msg.sender]>=value,"you dont have enough tokens to transfer");
        balanceof[msg.sender]-=value;
        balanceof[to]+=value;
        emit Transfer(msg.sender,to,value);
        return true;
    }
    function approve(address spender,uint256 value) public override returns(bool success){
        Allowance[msg.sender][spender] = value;
        emit Approve(msg.sender,spender, value);
        return true;
    }
    function transferFrom(address from,address to,uint256 value) public override returns(bool success){
        require(balanceof[from]>=value,"sender do not have enough tokens to transfer");
        require(value <= Allowance[from][msg.sender]);
        Allowance[from][msg.sender]-=value;
        balanceof[from]-=value;
        balanceof[to]+=value;
        emit Transfer(from, to , value);
        return true;

    }

}