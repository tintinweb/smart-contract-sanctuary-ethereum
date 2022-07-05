/**
 *Submitted for verification at Etherscan.io on 2022-07-05
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

   ERC20_STD ESTtoken = ERC20_STD(0xA19656cBa1C100B410d3d806B83E417582f67719);


address public user = msg.sender;

struct userInfo{
uint current_time;
uint total_reward;    
uint staking_time;
uint latest_time;
uint staked_value;
string claimAmount_msg;
string claimReward_msg;
}
mapping(address => userInfo) public data;


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


      function stake(uint256 token_value) public returns (uint stakevalue){
          
          require(ESTtoken.allowance(user,address(this))>=token_value,"insufficient allowace for staking");
          require(ESTtoken.balanceOf(user)>=token_value,"insufficient balance for staking");
          ESTtoken.transferFrom(user,address(this),token_value); 
          data[user].staking_time = block.timestamp;
          data[user].latest_time = data[user].staking_time;
          //data[user].total_reward=0;
          data[user].staked_value = token_value;
          return data[user].staked_value;
      }

      function showStakeValue() view public returns (uint value){
        return data[user].staked_value;
      }

      function showTotalReward(address _user) public returns(uint reward){
       _user = user;
      require( data[user].staked_value != 0 ,"no staking no reward");
      data[user].current_time= block.timestamp;
      uint x;
         uint y;
         uint percent;
         
      uint full_time = data[user].staking_time+300;
      if( data[user].current_time-data[user].staking_time<=300){
        x = data[user].current_time-data[user].latest_time;
      }else if(data[user].current_time-data[user].staking_time>=300 && data[user].latest_time<=full_time){
        x = full_time-data[user].latest_time;
      }else{
        x=0;
      }
      if(x>0  && data[user].current_time<=full_time){
      y = x/60;
      percent = data[user].staked_value*1/100;
      data[user].total_reward=y*percent;
      return (data[user].total_reward);
      }
      else if(data[user].current_time>=full_time){
       require(x!=0,"no reward"); 
         y=x/60;
        percent = data[user].staked_value*1/100;
        data[user].total_reward = y*percent;
        return (data[user].total_reward);
          }
         
        }
  

      function claimReward() public returns ( string memory msgs ){
         
         require(showTotalReward(user) != 0,"no reward yet");
           ESTtoken.transfer(user,showTotalReward(user));
        data[user].total_reward=0;
         data[user].latest_time=block.timestamp; 
         data[user].claimReward_msg = "successfully transfered reward";
         return data[user].claimReward_msg;
      }

      function showClaimReward_msg() view public returns(string memory msgs){
        return data[user].claimReward_msg;
      }

      function claimAmount() public returns (string memory msgs){
                 require(data[user].staked_value != 0,"no amount found all got returned");
                 ESTtoken.transfer(user,data[user].staked_value);
                 data[user].staked_value = 0;
                 data[user].claimAmount_msg = "all amount got widthdraw,now not eligible for reward";
           return data[user].claimAmount_msg;
      }
  

   function shoeClaimAmount_msg() public view returns(string memory msgs){
     return data[user].claimAmount_msg;
   }
}