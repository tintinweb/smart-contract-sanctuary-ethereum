// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IERC.sol";

contract Vest {
    
    //Vesting 

    struct VestingPriod{
        uint percent;
        uint startTime;
        uint vestingCount;
       uint MaxClaim;   
    }
    
    IERC20 token;

    constructor(address _token) {
        token = IERC20(_token);
    }
    uint maxPercent;
    bool Vesting;
    uint VestingCount;

    VestingPriod _vestingPeriod;

    mapping(uint => VestingPriod ) public PeriodtoPercent;
    mapping(address => uint) private TotalBalance;
    mapping(address => uint) private claimCount;
    mapping(address => uint) private claimedAmount;
    mapping(address => uint) private claimmable;

    mapping(address => uint) public TokenBalance;

    function _vesting() external{
       
        Vesting = true; 
    }
    

    function setVesting(uint StartTime, uint StartPercentage) external {
        require(Vesting, "VF");//Vesting was not set to true
        require(PeriodtoPercent[VestingCount].percent+StartPercentage <= 100, "TM");//Too much reduce to add up to 100
           VestingCount++;
           maxPercent += StartPercentage;

        PeriodtoPercent[VestingCount] = VestingPriod({
            percent : StartPercentage,
            startTime : StartTime,
            vestingCount : VestingCount,
              MaxClaim : maxPercent
        });

      

    }

    function claim() external {
        require(Vesting);
        require(claimCount[msg.sender] <= VestingCount,"CC");//Claiming Complete
        claimCount[msg.sender] ++;

        for(uint i = claimCount[msg.sender]; i<= VestingCount; i++){
            if(PeriodtoPercent[i].startTime < block.timestamp){
                claimmable[msg.sender] +=PeriodtoPercent[i].percent;
            }
            else 
            break;
        }
        
        require(claimmable[msg.sender] <= 100);
        

        uint _amount = (claimmable[msg.sender] *100) * TotalBalance[msg.sender]/10000;

        TotalBalance[msg.sender] -= _amount;
        claimedAmount[msg.sender] += claimmable[msg.sender]; 
  
        delete claimmable[msg.sender];

        token.transfer(msg.sender, _amount);


     
    }

    receive() external payable{}

    function buy(uint amount) external {
        TokenBalance[msg.sender] +=amount;
        TotalBalance[msg.sender] +=amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/IERC20.sol
interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}