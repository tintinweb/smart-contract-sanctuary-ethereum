// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract OptionIncentive {
    address owner;
    int256 public ht_price = 0;
    uint256 public threshold = 1;
    // uint256 public num_every_time = 1000000;
    mapping (address => uint256) public incentives;
    uint256 public totalIncentives;
    uint256 public totalDeposit;
    AggregatorV3Interface internal priceFeed;

    constructor() {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(0x779877A7B0D9E8603169DdbD7836e478b4624789);
    }

    function weHave() public view returns(uint256) {
        return address(this).balance;
    }

    function deposit() public payable {
        totalDeposit += msg.value;
    }

    function addIncentive(address _employee, uint256 _incentive) public {
        require(totalDeposit>(totalIncentives+_incentive), "Not enought left to incentive");
        require(msg.sender == owner, "Only owner can add incentives");
        incentives[_employee] = _incentive;
        totalIncentives += _incentive;
    }

    function getStockPrice() public payable {
        (
            /* uint80 roundID */,
            int256 answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        // return price;
        
        ht_price = int256(answer/(1e18));

    }

    function releaseIncentive(address _employee, uint256 amount) public {
        require(incentives[_employee] > 0, "Employee has no incentives");
        require(ht_price >= int256(threshold), "HT price is less than threshold");
        incentives[_employee] -= amount;
        totalIncentives -= amount;
        // _employee.call.value(amount)("");
        _employee.call{value: amount}("");
        // payable(_employee).transfer(num_every_time);
    }

    function getLeftIncentive(address _employee) public view returns (uint256) {
        return incentives[_employee];
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