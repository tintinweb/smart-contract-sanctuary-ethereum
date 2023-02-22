// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface  IERC20{

    function transfer(address,uint) external returns(bool);
    function transferfrom(address,address,uint)external returns (bool);
        
    
}
contract CrowdFunding {
    struct Campaign{
        address owner;
        string title;
        string desc;
        uint256 target;
        uint256 startAt;
        uint endAt;
        uint256 amountCollected;
        
        bool claimed;
        
        

    }
    IERC20 public immutable token;
    uint public count;
    

    mapping(uint256=>Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public pledgedAmount;

    constructor(address _token) {
        token = IERC20(_token);
       
    }
    

   event Launch(
    uint id,address indexed owner,uint target,uint startAt,uint endAt
   );  
   event Cancel(uint id);
   event Claim(uint id);

   function  launch (uint _target,uint _startAt,uint _endAt,string memory _desc,string memory _title)   external {
     require(_startAt>=block.timestamp,"Start time is less than current Block Timestamp");
     require(_endAt > _startAt,"End time is less than Start time");
    
     count++;
     campaigns[count]= Campaign(
        {
            owner:msg.sender,
            title:_title,
            target:_target,
            desc:_desc,
            startAt:_startAt,
            endAt:_endAt,
            amountCollected:0,
            claimed:false

        }
     );
     emit Launch(count, msg.sender, _target, _startAt, _endAt);

   }

}