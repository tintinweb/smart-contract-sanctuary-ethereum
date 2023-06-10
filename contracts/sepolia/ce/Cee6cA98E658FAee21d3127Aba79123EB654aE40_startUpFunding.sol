// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.7;

import "./funder.sol";

contract startUpFunding{
    
    /* State variable*/
    address private immutable i_Owner;
    address private dataFeed;

    struct startUp{
        funder ContractAddress;
        address userAddress;
        uint256 targetValue;
        uint256 Fundingtime;
    }
    
    startUp[] public userList;
    mapping(address=>address) public MappingUser;

    constructor(address _dataFeed) {
        dataFeed=_dataFeed;
        i_Owner=msg.sender;
    }

    function newStartUp(address newUsers,uint256 targetValue,uint256 Fundingtime) public OnlyOwner{
        new funder(newUsers,targetValue,Fundingtime,dataFeed);
        userList.push(startUp(new funder(newUsers,targetValue,Fundingtime,dataFeed),newUsers,targetValue,Fundingtime));
        MappingUser[newUsers]= address(new funder(newUsers,targetValue,Fundingtime,dataFeed));
    }

    modifier OnlyOwner(){
     require(i_Owner==msg.sender);
     _; 
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract funder  {
    /* State Vaiable*/
    address public immutable i_userOwner;
    uint256 public immutable i_targetValue;
    uint256 public totalFundRaised=0;
    uint256 public immutable i_Fundingtime;
    uint256 public immutable blockTime;
    AggregatorV3Interface public dataFeed;

    constructor(address UserAddress,uint256 _targetValue,uint256 _Fundingtime,address _dataFeed) {
        i_userOwner = UserAddress;
        i_targetValue=_targetValue;
        i_Fundingtime=_Fundingtime;
        blockTime=block.timestamp;
        dataFeed=AggregatorV3Interface(_dataFeed);
    }

    function fundMe(uint256 amount) public payable{
        require(getConversionRate(msg.value)> 2536783358701167 );
        require(totalFundRaised<=i_targetValue);
        require(block.timestamp-blockTime<i_Fundingtime);
        totalFundRaised=totalFundRaised+msg.value;
    }

    function withDrawFund() public OnlyOwner{
        require(block.timestamp-blockTime>i_Fundingtime);        
        payable(i_userOwner).transfer(address(this).balance);
    }

    function getPrice()
    internal
    view
    returns (uint256)
  {
    (, int256 answer, , , ) = dataFeed.latestRoundData();
    // ETH/USD rate in 18 digit
    return uint256(answer * 10000000000);
  }

    function getConversionRate(uint256 ethAmount)
    internal
    view
    returns (uint256)
  {
    uint256 ethPrice = getPrice();
    uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
    // the actual ETH/USD conversation rate, after adjusting the extra 0s.
    return ethAmountInUsd;
  }


    modifier OnlyOwner() {
        require(i_userOwner == msg.sender);
        _;
    }
}