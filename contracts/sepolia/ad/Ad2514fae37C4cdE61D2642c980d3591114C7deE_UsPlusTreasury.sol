/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

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


contract UsPlusTreasury {
  struct UsdSupplyReport {
    address reporter;
    uint value;
  }
  UsdSupplyReport[] public reports;
  mapping(address => bool) public reporters;
  uint public reportsLimit = 100;

  uint public initialUsdSupply;
  uint public currentUsdSupply;

  AggregatorV3Interface internal immutable btcPriceFeed;
  int256 public currentBtcPrice;

  // TODO: btcDepositToken

  constructor(uint _initialUsdSupply, address _btcPriceFeed) {
    initialUsdSupply = _initialUsdSupply;
    currentUsdSupply = _initialUsdSupply;

    btcPriceFeed = AggregatorV3Interface(_btcPriceFeed);

    determineBtcPrice();
  }

  function reportUsdSupply(uint value) public returns (uint) {
    bool alreadyReported = reporters[msg.sender];

    require(value > 0);
    require(alreadyReported == false,"you already submitted a report");

    // TODO: check if report deadline is reached based on block number
    // TODO: add a max number of reports for gas purposes

    reports.push( UsdSupplyReport(msg.sender,value) );
    reporters[msg.sender] = true;
    

    return getNumberOfReports();
  }

  function updateUsdSupply() public returns (uint) {
    require(reports.length >= 1,"there must be at least 1 report submitted");
    require(reports.length < reportsLimit,"maximum number of reports received");

    uint sum = 0;

    for (uint i=0; i < reports.length; i++) {
      UsdSupplyReport memory report = reports[i];

      sum += report.value;
    }

    uint averageValue = sum / reports.length;

    currentUsdSupply = averageValue;

    // TODO: give ratings for all reporters
    for (uint i=0; i < reports.length; i++) {
      UsdSupplyReport memory report = reports[i];

      delete reporters[report.reporter];
    }

    delete reports;


    return currentUsdSupply;
  }

  function determineBtcPrice() public returns (int256) {
    // TODO: only fetch value once every X blocks
    // TODO: average last N values for the past 30 days

    currentBtcPrice = getLatestBtcPrice() / int256(10**btcPriceFeed.decimals());

    return currentBtcPrice;
  }

   /**
   * @notice Returns the latest price
   *
   * @return latest price
   */
   function getLatestBtcPrice() public view returns (int256) {
      (
          uint80 roundID,
          int256 price,
          uint256 startedAt,
          uint256 timeStamp,
          uint80 answeredInRound
      ) = btcPriceFeed.latestRoundData();
      return price;
  }

  /**
   * @notice Returns the Price Feed address
   *
   * @return Price Feed address
   */
  function getBtcPriceFeed() public view returns (AggregatorV3Interface) {
      return btcPriceFeed;
  }

  function getNumberOfReports() public view returns (uint) {
    return reports.length;
  }
}