// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "AggregatorV3Interface.sol"; // similar to npm import!

// Objective: accept payment
contract FundMe {
    // handle user total payment here
    mapping(address => uint256) public addressToAmountFunded;
    // handle payment history
    struct Payments {
        address senderAddress;
        uint256 sentFund;
        uint256 timestamp;
    }
    Payments[] public paymentHistory;
    address public owner;

    // Chainlink interface - ABI
    AggregatorV3Interface internal dataFeed;

    // ---- constructor: will be executed at the beginning of the contracts,
    // and the variables will be available through the contract
    constructor() {
        /**
         * Network: Sepolia
         * Aggregator: ETH/USD
         * Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
         */
        dataFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
        // set deployer as contract owner
        owner = msg.sender;
    }

    // ---- modifier: similar to Python decorator
    // ownership modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "You are NOT the owner!"); // msg.<something> only works for payable function!
        _; // the function code will be run here, on the under score (_)
    }

    // get the version
    function getVersion() public view returns (uint256) {
        return dataFeed.version();
    }

    // get the latest ETH/USD price
    function getPrice() public view returns (uint256) {
        (
            ,
            /* uint80 roundID */ int answer /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/, // 181203000000 in 8 decimals (1812.03)
            ,
            ,

        ) = dataFeed.latestRoundData(); // (,int answer,,,) = dataFeed.latestRoundData();
        return uint256(answer); // return in uint
    }

    // get the conversion rate
    function getUsdToWei(uint256 _usdAmount) public view returns (uint256) {
        return (_usdAmount * (10 ** 26)) / getPrice();
    }

    // payable (RED) function, allow user to interact with payment on this function!
    function fund() public payable {
        // msg.sender: the user/sender (the one that call the function) address
        // msg.value: amount of token sent/paid

        // set minimum payment, in other currency (e.g., USD)
        uint256 minUsd = 5;
        uint256 minWei = getUsdToWei(minUsd);
        // revert function/transaction if the paid fund is below the minimum USD
        require(msg.value >= minWei, "Please spend more ETH!"); // refund if not fulfilled!

        // store the funds here
        addressToAmountFunded[msg.sender] += msg.value;
        paymentHistory.push(Payments(msg.sender, msg.value, block.timestamp)); // current block timestamp
    }

    // withdrawal function
    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        // reset all balance into zero after a successful withdrawal!
        for (
            uint256 funderIndex = 0;
            funderIndex < paymentHistory.length;
            funderIndex++
        ) {
            address funder = paymentHistory[funderIndex].senderAddress; // get funder address
            addressToAmountFunded[funder] = 0; // reset funder total funds to zero
        }
        delete paymentHistory;
        assert(paymentHistory.length == 0);
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