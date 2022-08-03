/**
 *Submitted for verification at Etherscan.io on 2022-08-02
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

// Note 

// 1-> Contract owner approves the amount to staking contract 
// 2-> Depositors approves the amount to contract before
// 3-> Holds stake for one minute
// 4-> Send back withdraw to user account

contract Staking{
    
    uint percentAge;
    address owner;
    mapping (address=>uint) public depositedBlanace;
    mapping(address=> uint)  Withdrawtime;
     IERC20 token;

    constructor(address tokenAddress , uint stakingRewardPercent , address TokenOwner){
        token = IERC20(address(tokenAddress));
        percentAge= stakingRewardPercent;
        owner = TokenOwner;
    }

    function deposit(uint amount) external returns( bool){
      
        require(token.balanceOf(msg.sender)>amount,"You've INSUFFICIENT TOKENS");
        token.transferFrom(msg.sender , owner , amount);
        depositedBlanace[msg.sender]=amount;
        Withdrawtime[msg.sender]  = block.timestamp+20;
        return true;
    }
    
    modifier timeReached(){
        require(depositedBlanace[msg.sender]>0,"You have'nt any amount");

        _;
    }
     
    function withDraw() external timeReached  returns (bool){
           uint reward;
         if(Withdrawtime[msg.sender]>block.timestamp){     
            uint timepercentage = 100 - ((Withdrawtime[msg.sender]-block.timestamp)*100)/20;
            reward = (depositedBlanace[msg.sender]*timepercentage)/100;
            token.transferFrom( owner, msg.sender ,(reward+depositedBlanace[msg.sender]));
            depositedBlanace[msg.sender]= 0;
            Withdrawtime[msg.sender] = 0;


         }
         else{
            reward = ((depositedBlanace[msg.sender]*percentAge)/100);
            token.transferFrom( owner, msg.sender ,reward);
            depositedBlanace[msg.sender]= 0;
            Withdrawtime[msg.sender] = 0;
         }
          
             

         return true;
    }


        
  

}