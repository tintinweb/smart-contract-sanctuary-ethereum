/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;



interface IBEP20 {
        function totalSupply() external view returns (uint256);
        function decimals() external view returns (uint8);
        function symbol() external view returns (string memory);
        function name() external view returns (string memory);
        function balanceOf(address account) external view returns (uint256);
        function transfer(address recipient, uint256 amount) external returns (bool);
        function allowance(address _owner, address spender) external view returns (uint256);
        function approve(address spender, uint256 amount) external returns (bool);
        function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner,address indexed spender,uint256 value);
    }


    
 contract Staking {

   struct Staketoken {
     uint256  opening_time ;
     uint256  closing_time ;
   }

    mapping(address => uint256) public balance;

   
    mapping(address => uint) public Stakingbalance;
    mapping(address => bool) public hasstaking;
    mapping(address => uint) public Staking_Time_Plan;
    mapping(address => Staketoken) public Staking_Time_Info;
    address[] public stakers;
    uint256  public start_time = block.timestamp;
    uint256  public end_time ;

    struct Plan  {
        
    string Five_Mints ;
    string Ten_Mints ;
}
    Plan public plan;
    uint internal _plan ;
    constructor(address _stakingToken, address _rewardToken)  {
       owner = msg.sender;   
       stakingToken = IBEP20(_stakingToken);    
       rewardToken = IBEP20(_rewardToken);      
    }
    IBEP20 public stakingToken;
    IBEP20 public rewardToken;
    address public owner;

   //Stake Token 
    function StakeToken(uint amount  , uint _time_Plan) public  {
        require(amount>0 , "amount can't lessthan 0");
        require(_time_Plan == 5 || _time_Plan == 10);
    if(_time_Plan == 5){
    Staking_Time_Info[msg.sender].opening_time = block.timestamp;
    Staking_Time_Info[msg.sender].closing_time = Staking_Time_Info[msg.sender].opening_time + 300;
    }else{
         Staking_Time_Info[msg.sender].closing_time = Staking_Time_Info[msg.sender].opening_time + 600;
    }
       stakingToken.transferFrom(msg.sender, address(this), amount);
    _plan = _time_Plan;
    
    Stakingbalance[msg.sender]=Stakingbalance[msg.sender] + amount;
    Staking_Time_Plan[msg.sender]=_time_Plan;
    if(!hasstaking[msg.sender]){
      stakers.push(msg.sender);
     }
    hasstaking[msg.sender]= true;
    }

  //Reward Calculate According to per Minutes (Note: Please Enter atleast 100 token for better understanding calculation)
   function Reward_calculate() public view returns(uint256 reward) {
       uint timespend= block.timestamp - start_time;
        uint TimeInMint= timespend / 60;
        uint _balance;
        
        if(Staking_Time_Plan[msg.sender] == 5){
          
            _balance = Stakingbalance[msg.sender] / 50 ;
            reward = TimeInMint * _balance;
        }else{
             _balance = Stakingbalance[msg.sender] / 50 ;
            reward = TimeInMint * _balance;
        }
   }

   //Send Reward To the Staker
    function Send_Reward( address staker ) public {
    require(msg.sender == owner , "only owner run this function");
    require(block.timestamp >=   Staking_Time_Info[staker].closing_time , "You cannot withdraw amount before time completed");
    uint timespend= block.timestamp -  Staking_Time_Info[staker].opening_time;
    uint TimeInMint= timespend / 60;
    for(uint i =0 ; i<stakers.length; i++){
        
        uint _balance;
          uint reward;
        if(Staking_Time_Plan[staker] == 5){
          
            _balance = Stakingbalance[staker] / 50 ;
            reward = TimeInMint * _balance;
        }else{
             _balance = Stakingbalance[staker] / 50 ;
            reward = TimeInMint * _balance;
        }
   
     rewardToken.transferFrom(msg.sender,staker,reward);
    }
}

//Withdraw the Token
function Withdraw() public {
       require(block.timestamp >=   Staking_Time_Info[msg.sender].closing_time , "You cannot withdraw amount before time completed");
        uint balancee = Stakingbalance[msg.sender];
        require(balancee>0);
        stakingToken.transferFrom(address(this), msg.sender, balancee);
    }

function unStakeToken() public {
    uint _balance = Stakingbalance[msg.sender];
    require(_balance>0);
   
     stakingToken.transferFrom(address(this), msg.sender, _balance);
       Stakingbalance[msg.sender]=0;
       hasstaking[msg.sender]= false;
}
 
}