/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


contract ScriptUpgradeableERC20 {
    string public name; 
    string public symbol;
    uint8 public decimals;
    uint256 public supply;

    mapping(address=>uint) public balances;
    mapping(address=>mapping(address=>uint)) public allowed;

    event Transfer(address sender, address receiver, uint256 tokens);
    event Approval(address sender, address delegate, uint256 tokens);


    function initialize(string memory _name, string memory _symbol, uint8 _decimals,uint256 _supply) public payable {
        name=_name;
        symbol=_symbol;
        decimals=_decimals;
        supply=_supply;
        balances[msg.sender]=supply;
    }

    //Functions

    // It returns the total number of tokens that you have
    function totalSupply() external view returns(uint256){
        return supply;
    } 

    // It returns how many tokens does this person have
    function balanceOf(address tokenOwner) external view returns(uint){
        return balances[tokenOwner];
    } 

    //It helps in transferring from your account to another person
    function transfer(address receiver, uint numTokens) external  returns(bool){
        require(balances[msg.sender]>=numTokens);
        balances[msg.sender]-=numTokens;
        balances[receiver]+=numTokens;
        emit Transfer(msg.sender,receiver,numTokens);
        return true;
    } 

    //Used to delegate authority to send tokens without token owner
    function approve(address delegate,uint numTokens) external returns(bool){
        allowed[msg.sender][delegate]=numTokens;
        emit Approval(msg.sender,delegate,numTokens);
        return true;
    }
    
    //How much has the owner delegated/approved to the delegate 
    function allowance(address owner, address delegate) external view returns(uint){
        return allowed[owner][delegate];
    } 

}