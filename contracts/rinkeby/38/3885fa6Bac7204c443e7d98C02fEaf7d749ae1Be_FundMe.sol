// Create a contract to fund and withdraw ETH with a minimum amount to fund 50$
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import chainlink interface to get the live ETH price
import "AggregatorV3Interface.sol";

contract FundMe {
    // create a dictoreny like mapping between address and funded amount
    mapping(address => uint256) public adrressToAmountFunded;
    address[] public funders;
    address public owner;

    //protect the fund by defining the owner varaiable with constructor
    constructor() {
        owner = msg.sender;
    }

    function fund() public payable {
        // Set $50 as the minimum amount can be funded, otherwise reject the transction and revert back a msg
        uint256 minimumusd = 50 * 10 * 18; // all returned numbers has 18 decimel
        require(
            getConversionRate(msg.value) >= minimumusd,
            "You need to spend more ETH!"
        );
        //msg.sender & msg.value are contract keyword for payable functions
        adrressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        // get the contract address from chainlinek docs (Rinkeby Testnet)
        address ETHUSDaddress = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
        //make a function Call from the imported chainlink intreface
        AggregatorV3Interface priceFeed = AggregatorV3Interface(ETHUSDaddress);
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        // get the contract address from chainlinek docs (Rinkeby Testnet)
        address ETHUSDaddress = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
        //make a function Call from the imported chainlink intreface
        AggregatorV3Interface priceFeed = AggregatorV3Interface(ETHUSDaddress);
        // latestRoundData function return 5 variable and we need to call only 1
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000); //used uint to aviod casting error from int to unit
    }

    // Get the USD value for the funded amount
    function getConversionRate(uint256 ethamount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethamountInusd = (ethPrice * ethamount) / 10000000000;
        return ethamountInusd;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You're not the contract owner Buddy !");
        _;
    }

    function withdraw() public payable onlyOwner {
        //withdraw all the fund in the contract / "this" is a keyword
        payable(msg.sender).transfer(address(this).balance);
        // reset the funders array to zero after the withdraw
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            adrressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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