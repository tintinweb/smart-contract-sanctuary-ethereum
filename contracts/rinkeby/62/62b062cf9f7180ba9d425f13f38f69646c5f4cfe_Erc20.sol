/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;


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

    //  State Variables

    string public  name;
    string public  symbol;
    uint   _totalSupply;
    uint8  public decimals ;
    uint _fee;
    address public immutable owner;
    mapping(address=>uint256)  balances;
    mapping(address=>mapping(address=>uint256)) allowed;
    mapping(address=>bool) whitelisted;

    
    constructor(){      
       name="MyCoin";
       symbol="MC"; 
        _fee=2;
       _totalSupply=100000*1e18;
       decimals=18;
       balances[msg.sender] = _totalSupply;
       owner = msg.sender;
    }

    
    //FUNCTIONS
    function totalSupply() external override  view returns (uint256){
            return _totalSupply;
    }


    function balanceOf(address tokenOwner) external override view returns (uint){
           return balances[tokenOwner];
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

   function transfer(address to, uint tokens) external override returns (bool){
          require(balances[msg.sender]>=tokens,"You dont have enough money");
          uint deliverable;
          uint deductedAmount; 
          balances[msg.sender] -=tokens;
          deductedAmount = (_fee*tokens)/100;
          deliverable = tokens - deductedAmount; 
          balances[to] +=deliverable;
          balances[owner] +=deductedAmount;
          emit Transfer( msg.sender, to , deliverable);
          return true;
    } 

    function transferFrom(address from, address to, uint tokens) external override returns (bool){

            uint  allowonce = allowed[from][msg.sender];
            // uint deliverable;
            // uint deductedAmount;
            require(balances[from]>=tokens && allowonce>=tokens,"Insufficient balance");

            //WhiteListed by owner don't have to pay fee on transaction
            // if(whitelisted[msg.sender]){
        
            balances[from] -=tokens;
            balances[to]+=tokens;
            allowed[from][msg.sender] -=tokens;
            emit Transfer(from,to,tokens);  
      
            // }     
            // else{
            // deductedAmount = (_fee*tokens)/100;
            // deliverable = tokens - deductedAmount; 
            // balances[from] -=tokens;
            // balances[to] +=deliverable;
            // balances[owner]+=deductedAmount;
            // allowed[from][msg.sender] -=tokens;
            // emit Transfer(from,to,deliverable);
            // }

            return true;
    }

    // EXTRAS
    modifier isOwner(){
        require(msg.sender==owner, "You're not Owner");
        _;
    }

    // function whitelist(address User) external isOwner returns (bool){
    //       whitelisted[User]=true;
    //       return true;
    // }

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