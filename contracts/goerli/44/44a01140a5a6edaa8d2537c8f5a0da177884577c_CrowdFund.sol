/**
 *Submitted for verification at Etherscan.io on 2023-01-21
*/

// SPDX-License-Identifier: MIT
pragma solidity^0.8.17;

interface IERC20 {
    function transfer(address,uint) external returns(bool);

    function transferFrom(address,address,uint) external returns(bool);
}

contract CrowdFund {
    event Launch(
        uint id,
        address indexed creator,
        uint goal,
        uint32 startAt,
        uint32 endAt
    );

    event Cancel(uint id);
    event Pledge(uint indexed id,address indexed caller,uint amount);
    event Unpledge(uint indexed id,address indexed caller,uint amount);
    event Claim(uint id);
    event Refund(uint id,address indexed caller,uint amount);

   struct Campaign{
       //creator of Campaign这场捐款的创建者
       address creater;
       //Amount of tokens to raise 需要募集的数量
       uint goal;
       //total amount pledged实际募集到的币的总数
       uint pledged;
       //Timestamp of start of campaign这场募捐开始的时候的时间戳
       uint32 startAt;
       //Timestamp of end of campaign这场募捐结束的时候的时间戳
       uint32 endAt;
       //True if goal have reached and the creator have withdraw the tokens;
       //如果这场募捐设定的目标金额达到了，而且募捐发起者把币取走了，
       bool claimed;
   }

   IERC20 public immutable token;
   //Total amount of campaigns created所有创建的募捐的数量
   //It is also used to generate id for new campaigns;也用于为新的募捐创建id
   uint public count;
   //Mapping from id to Campaign  将募捐的id和Campaign map到一起
   mapping(uint => Campaign) public campaigns;

   //Mapping from campaign id => pledger =>amount pledged;
   //建立一个匹配：募捐ID =》 捐赠者地址 =》捐赠的数量
   mapping(uint => mapping(address => uint)) public pledgeAmount;

   constructor(address _token){
       token = IERC20(_token);
   }

   function launch(uint _goal,uint32 _startAt,uint32 _endAt ) external{
       require(_startAt > block.timestamp,"start at < now!");
       require(_endAt > _startAt,"end at < start at!");
       require(_endAt < block.timestamp + 90 days,"end at < max duration!");

       count += 1;

       campaigns[count] = Campaign({
           creater:msg.sender,
           goal:_goal,
           pledged:0,
           startAt:_startAt,
           endAt:_endAt,
           claimed:false

       });

       emit Launch(count, msg.sender, _goal, _startAt, _endAt);
   }
//在众筹没开始之前 可以取消这个众筹
   function cancel(uint _id) external{
       Campaign memory campaign = campaigns[_id];

       require(campaign.creater == msg.sender,"not creater");
       require(block.timestamp < campaign.startAt,"campaign had started!");

       delete campaigns[_id];
       emit Cancel(_id);
   }


   function pledge(uint _id,uint _amount) external{
       Campaign storage campaign = campaigns[_id];
       require(block.timestamp > campaign.startAt,"campaign not start yet!");
       require(block.timestamp < campaign.endAt,"ended!");
       
      
       campaign.pledged += _amount;

       pledgeAmount[_id][msg.sender] = _amount;

       token.transferFrom(msg.sender,address(this),_amount);

       emit Pledge(_id,msg.sender,_amount);

   }

   function unpledge(uint _id,uint _amount) external{
       Campaign storage campaign = campaigns[_id];
       require(block.timestamp <= campaign.endAt,"ended");
       
       require(block.timestamp >= campaign.startAt,"not start yet");

       campaign.pledged -= _amount;

       pledgeAmount[_id][msg.sender] -= _amount;

       token.transfer(msg.sender,_amount);

       emit Unpledge(_id, msg.sender, _amount);
       
   }

   function claim(uint _id) external{

       Campaign storage campaign = campaigns[_id];

       require(campaign.creater == msg.sender,"not the creater!");

       require(block.timestamp > campaign.endAt,"not end!");

       require(campaign.pledged >= campaign.goal,"pledged < goal");

       require(!campaign.claimed,"already claimed!");

       token.transferFrom(address(this),msg.sender,campaign.goal);

       campaign.claimed = true;

       emit Claim(_id);

   }

   function refund(uint _id)  external{
       Campaign memory campaign = campaigns[_id];

       require(block.timestamp > campaign.endAt,"campaign not ended yet!");

       require(campaign.pledged < campaign.goal,"pledged > goal!");

       uint bal = pledgeAmount[_id][msg.sender];

       pledgeAmount[_id][msg.sender] = 0;

       token.transfer(msg.sender,bal);

       emit Refund(_id, msg.sender, bal);

   }
}