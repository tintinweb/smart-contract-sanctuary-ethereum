/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.5.0 < 0.9.0;

interface IERC20 {

//Fuction that use in ERC20 token  
    function decimals() external view returns(uint);  
    function totalSupply() external view returns(uint);
    function balanceOf(address Owner) external view returns (uint);
    function allowance(address tokenOwner, address spender) external view returns(uint);
    function transfer(address to, uint token) external returns(bool);
    function approve (address spender , uint token ) external returns (bool);
    function transferFrom(address from, address to , uint token) external returns(bool); 

//Events use in ERC20
    event approval(address indexed Owner, address indexed to, uint token);
    event Transfer(address from ,address to , uint token);
    
} 

contract ERC20 is IERC20 {
 //state variables
 string public name;
 string public symbol;
 uint _decimals;
 uint totalsupply;
 address public owner;
 mapping (address =>uint) tokenbalance;
 mapping (address=>mapping(address=>uint)) allowed;
 

constructor(){
    //state variable declaration
    name="ERC20";
    symbol="USDT";
    _decimals=18;
    totalsupply=100000*10**18;
    owner=msg.sender;
    tokenbalance[msg.sender]=totalsupply;
    }

    function decimals() public view override returns(uint){
        return _decimals;
    }
    function totalSupply() external view override  returns(uint){
    return totalsupply;
    }
    function balanceOf(address Owner) external view override  returns (uint){
         return tokenbalance[Owner];
    }

    function allowance(address tokenOwner, address spender) external view override  returns(uint){
            return allowed[tokenOwner][spender]; //allowe the spender are allow to burn patucular token in partucular time

    }

    function transfer(address to, uint token) external override  returns(bool){

            require(tokenbalance [msg.sender] >= token,"low balance");
            tokenbalance[msg.sender] -= token;
            tokenbalance[to] += token;
            emit Transfer(msg.sender, to, token);
            return true;
    }

    function approve (address spender , uint token ) external override  returns (bool){
     require(tokenbalance[msg.sender] >= token, "You are not approved,low balnce");
     allowed[msg.sender][spender] =token; //check the sender and spender are in allow list and approve
     emit approval(msg.sender, spender, token);
     return true;
    }

    function transferFrom(address from, address to , uint token) external override  returns(bool){

   uint allowbalance=allowed[from][msg.sender]; //here msg.sender the third part who execute this function and from is owner
   require(allowbalance >= token," insufficient balance");
   tokenbalance[from] -= token;
   tokenbalance[to] +=token;
   allowed[from][msg.sender]-=token;
   emit Transfer(from, to, token);
   return true;
    }
}