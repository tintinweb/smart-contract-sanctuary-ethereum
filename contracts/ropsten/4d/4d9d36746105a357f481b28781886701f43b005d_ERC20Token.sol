/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC20
{
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}
contract ERC20Token is IERC20
{
    string public constant name="ERC20Token";
    string public constant symbol="MyToken";
    uint256 public constant decimal=10;
    uint256 _totalSupply=8000;

mapping(address=>uint256) balances;
mapping(address=>mapping(address=>uint256))allowed;

constructor(){
    balances[msg.sender]=_totalSupply;
}
function totalSupply() public override view returns(uint256)
{
    return _totalSupply;
}
function balanceOf(address tokenOwner) public override view returns(uint256)
{
    return balances[tokenOwner];
}
function transfer(address receiver, uint256 numtoken) public override  returns(bool)
{
    require(numtoken<=balances[msg.sender],"insufficent Tokens");
    balances[msg.sender]=balances[msg.sender]-numtoken;
    balances[receiver]=balances[receiver]+numtoken;
    emit Transfer(msg.sender,receiver,numtoken);
    return true;
}
function approve(address delegate,uint256 numToken) public override  returns(bool)
{
 allowed[msg.sender][delegate]=numToken;
 emit Approval(msg.sender,delegate,numToken);
 return true;
}
function allowance(address owner,address delegate) public override view returns(uint256)
{
    return allowed[owner][delegate];
}
function transferFrom(address owner,address buyer,uint256 numTokens) public override returns(bool)
{
    require(numTokens<=balances[owner],"Insufficent Tokens ownwer wallet");
    require(numTokens<=allowed[owner][msg.sender]);
    balances[owner]=balances[owner]-numTokens;
    allowed[owner][msg.sender]=allowed[owner][msg.sender]-numTokens;
    balances[buyer]=balances[buyer]+numTokens;

    emit Transfer(owner,buyer,numTokens);
    return true; 
} 
}