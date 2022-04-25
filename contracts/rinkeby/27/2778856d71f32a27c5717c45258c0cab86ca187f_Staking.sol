/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

//SPDX-License-Identifier: MIT
 pragma solidity ^0.8.7;



 contract Staking {


 mapping(address => uint256) public balance;
 mapping(address => uint) public Stakingbalance;
  mapping(address => bool) public hasstaking;
 mapping(address => uint) public Staking_Time;

  address[] public stakers;
  
uint256  public start_time = block.timestamp;

// uint256  public end_time = start_time + 300;
uint256  public end_time ;





uint256  totalToken = 1000;

address owner;

 struct Plan  {
    string Five_Mints ;
    string Ten_Mints ;
}
Plan public plan;

uint internal _plan ;

constructor() {
  balance[msg.sender] = totalToken;
  
  owner = msg.sender;

}

function MintToken() public {
    balance[msg.sender] = totalToken;

}

 function _transfer(address _from, address _to, uint256 _value) internal {
        
        require(_to != address(0));
        balance[_from] = balance[_from] - (_value);
        balance[_to] = balance[_to] + (_value);
        
    }


function StakeToken(uint amount  , uint _time_Plan) public {
    require(amount>0 , "amount can't lessthan 0");
    require(_time_Plan == 5 || _time_Plan == 10);
  if(_time_Plan == 5){
      end_time = start_time + 300;
  }else{
      end_time = start_time + 600;

  }

    _plan = _time_Plan;
  _transfer(msg.sender, address(this), amount);

  Stakingbalance[msg.sender]=Stakingbalance[msg.sender] + amount;
  
  Staking_Time[msg.sender]=_time_Plan;

  if(!hasstaking[msg.sender]){
      stakers.push(msg.sender);
  }

  hasstaking[msg.sender]= true;
  



}


   


function RewardToken() public {

    require(msg.sender == owner , "only owner run this function");
    require(block.timestamp >= end_time , "You cannot withdraw amount before time completed");

    uint timespend= block.timestamp - start_time;
    uint TimeInMint= timespend / 60;
    

    for(uint i =0 ; i<stakers.length; i++){
        address senderr = stakers[i];
        uint balance;
          uint reward;
       
        if(Staking_Time[senderr] == 5){
          // balance = Stakingbalance[senderr] /100 * 10 ;
            balance = Stakingbalance[senderr] / 50 ;
            reward = TimeInMint * balance;

        }else{
             balance = Stakingbalance[senderr] / 50 ;
            reward = TimeInMint * balance;
        }


    _transfer(msg.sender, senderr, reward);
      

    }

}



function unStakeToken() public {
    uint balance = Stakingbalance[msg.sender];
    require(balance>0); 

     _transfer(address(this)  , msg.sender ,  balance);

       Stakingbalance[msg.sender]=0;
       hasstaking[msg.sender]= false;
       

}



 }