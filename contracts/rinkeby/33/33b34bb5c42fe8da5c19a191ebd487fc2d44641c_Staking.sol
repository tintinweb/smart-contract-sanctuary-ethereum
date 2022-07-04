/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-License-Identifier: GPL-3.8
pragma solidity 0.8.7;



interface ERC20_STD 
 {

    function name() external view returns (string memory);
function symbol() external view  returns (string memory);
function decimals() external view  returns (uint8);
function totalSupply() external view   returns (uint256);
function balanceOf(address _owner) external view returns (uint256 balance);
function transfer(address _to, uint256 _value) external returns (bool success);
function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
function approve(address _spender, uint256 _value) external returns (bool success);

function allowance(address _owner, address _spender) external view  returns (uint256 remaining);

// event Transfer(address indexed _from, address indexed _to, uint256 _value);
// event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    }

contract Ownership //2nd contract to set contract owner
    {
 
     address public contractOwner;
     address public newOwner;

     event TransferOwnership(address indexed _from,address indexed _to);

     constructor() {
         contractOwner = msg.sender;
     }

     function changeOwner(address _to) public {
         require(msg.sender == contractOwner,"Only owner of contract can change owner");
         newOwner= _to;
     }

     function acceptowner() public{
    
    require(msg.sender == newOwner,"only new owne can accept");
    contractOwner = newOwner;
    emit TransferOwnership(contractOwner,newOwner);
    newOwner = address(0);
     }

    }

contract Staking is Ownership //to define function of abstract contract
{

   ERC20_STD ESTtoken = ERC20_STD(0xF7C57e9A03D68648F93Ac88e820f008aF41daa52);
   uint public staking_time;
   uint public total_reward;
   uint public latest_time;
   uint public staked_value=0;
   string public claimAmount_msg = "";
      string public claimReward_msg = "";


   constructor(){

   }

     function getCurrentTokenName() view public returns(string memory){
        return ESTtoken.name();
    }
    

        function getCurrentTokenSymbol() view public returns(string memory){
        return ESTtoken.symbol();
    }

        function getCurrentTokenDecimal() view public returns(uint){
        return ESTtoken.decimals();
    }

      function getCurrentTokenTotalSupply() view public returns(uint){
        return ESTtoken.totalSupply();
    }

       function getBalance(address _user) view  public returns(uint256){
        
                return ESTtoken.balanceOf(_user);

    }

       function giveUsApproval(address _us,uint _value) public returns (bool) {
           require(ESTtoken.balanceOf(msg.sender)>= _value,"insuffcient tokens please provide valide amount");
           ESTtoken.approve(_us,_value);
           return true;
       }


      function checkHowMuchWeHaveApprovalFromYourSide() view public returns (uint256){
         return ESTtoken.allowance(msg.sender,address(this));
      }

      function stake(uint256 token_value) public returns (uint stakevalue){
          require(ESTtoken.allowance(msg.sender,address(this))>=token_value,"insufficient allowace for staking");
          require(ESTtoken.balanceOf(msg.sender)>=token_value,"insufficient balance for staking");
          ESTtoken.transferFrom(msg.sender,address(this),token_value); 
          staking_time = block.timestamp;
          latest_time = staking_time;
          staked_value = token_value;
          return staked_value;
      }

      function showStakeValue() view public returns (uint value){
        return staked_value;
      }

      function showTotalReward()  public returns(uint reward){
       
    
      require( staked_value != 0 ,"no staking no reward");
      uint current_time= block.timestamp;
      uint x;
         uint y;
         uint percent;
         
      uint full_time = staking_time+300;
      if( current_time-staking_time<=300){
        x = current_time-latest_time;
      }else if(current_time-staking_time>=300 && latest_time<=full_time){
        x = full_time-latest_time;
      }else{
        x=0;
      }
      if(x>0  && current_time<=full_time){
      y = x/60;
      percent = staked_value*1/100;
      total_reward=y*percent;
      return (total_reward);
      }
      else if(current_time>=full_time){
       require(x!=0,"no reward"); 
         y=x/60;
        percent = staked_value*1/100;
        total_reward = y*percent;
        return (total_reward);
          }
         
        }
     
     

      function claimReward() public returns ( string memory msgs ){
         if(total_reward!=0){
           ESTtoken.transfer(msg.sender,total_reward);
        total_reward=0;
         latest_time=block.timestamp; 
         claimReward_msg = "successfully transfered reward";
         return "successfully transfered reward";
         }else{
           claimReward_msg ="no reward yet";
           return "no reward yet";
         }
     
      }

      function showClaimReward_msg() view public returns(string memory msgs){
        return claimReward_msg;
      }

      function claimAmount() public returns (string memory msgs){
                 if(staked_value != 0){ESTtoken.transfer(msg.sender,staked_value);
                 staked_value = 0;
                 claimAmount_msg = "all amount got widthdraw,now not eligible for reward";
           return "all amount got widthdraw,now not eligible for reward";}else{
             claimAmount_msg = "no amount found all got returned";
             return "no amount found all got returned";
           }     
      }
  

   function shoeClaimAmount_msg() public view returns(string memory msgs){
     return claimAmount_msg;
   }
}