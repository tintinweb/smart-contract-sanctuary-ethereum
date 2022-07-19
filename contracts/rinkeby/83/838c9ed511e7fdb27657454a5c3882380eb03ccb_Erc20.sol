/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
interface IERC20{
//Functions
function totalSupply() external  view returns (uint256);
function balanceOf(address tokenOwner) external view returns (uint);
function allowance(address tokenOwner, address spender)external view returns (uint);
function transfer(address to, uint tokens) external returns (bool);
function approve(address spender, uint tokens)  external returns (bool);
function transferFrom(address from, address to, uint tokens) external returns (bool);

//Events
event Approval(address indexed tokenOwner, address indexed spender,uint tokens);
event Transfer(address indexed from, address indexed to,uint tokens);

}

 contract Erc20 is IERC20{
    
    string public  _name;
    string public  _symbol;
    uint   public _totalSupply;
    uint8  public _decimals ;
    address  immutable owner;
    mapping(address=>uint256)  balances;
    mapping(address=>mapping(address=>uint256)) allowed;


    constructor(){
       _name="EmiCoin";
       _symbol="EMC";
       _totalSupply=100000;
       balances[msg.sender] = _totalSupply;
       owner = msg.sender;
    }
    
    //TotalSupply
    function totalSupply() external override  view returns (uint256){
            return _totalSupply;
    }
    //to find balance

     function balanceOf(address tokenOwner) external override view returns (uint){
           return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) external override returns (bool){
          require(balances[msg.sender]>=tokens,"You dont have enough money");
          balances[msg.sender] -=tokens;
          balances[to] +=tokens;
          return true;
          

    } 

    function allowance(address tokenOwner, address spender)external  override view returns (uint ){
        return allowed[tokenOwner][spender];

    } 

   function approve(address spender, uint tokens)  external override returns (bool){
         require(balances[msg.sender]>tokens);
         allowed[msg.sender][spender] = tokens;
         emit Approval(msg.sender,spender,tokens);
         return true;
   }

   function transferFrom(address from, address to, uint tokens) external override returns (bool)
  {
            uint  allowonce = allowed[from][msg.sender];
            require(balances[from]>=tokens && allowonce>=tokens,"Insufficient balance");
            balances[to] +=tokens;
            balances[from] -=tokens;
            allowed[from][msg.sender] -=tokens;
            emit Transfer(from,to,tokens);
            return true;
  }

    


    // EXTRAS

    modifier isOwner(){
        require(msg.sender==owner, "You're not Owner");
        _;
    }

    function Mint(uint amount) external isOwner returns (bool){
         
         balances[msg.sender]+=amount;
        _totalSupply+=amount;
        return true;
    }

    function Burn(uint amount) external isOwner returns(bool){
        require(balances[msg.sender]>amount,"Insufficient balance");
        balances[msg.sender]-=amount;
        _totalSupply -=amount;
        return true;
    }


}