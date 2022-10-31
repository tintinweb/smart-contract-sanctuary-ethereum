//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./PriceConvertor.sol";

error FundMe__NotOwner();

/**
 * @title A contract form crowd funding
 * @author Jatin
 * @notice This contract is to demo a sample funding contract.
 * @dev This implements price feeds as our library.
 */
contract FundMe {
    //Type Declerations
    using PriceConvertor for uint256;

    //State Variables
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;
    uint256 public constant MIN_USD = 50 * 1e18;
    address private immutable i_owner;

    modifier onlyOwner() {
        //require(msg.sender == i_owner, "SEnder is not owner");
        //this one saves more gas.
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    constructor(address priceFeedAddress) {
        // the msg.sender in constructor will be the one who deploys the contract.
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // receive() external payable {
    //     fund();
    // }

    // fallback() external payable {
    //     fund();
    // }

    /**
     * @notice This function funds this contract.
     * @dev This implements price feeds as our library.
     */
    function fund() public payable {
        // Want to be able to set a minimum fund amount in USD.
        // HOw to send ETH to this contract.
        // this means that is the value sent greater than 1 eth.
        require(
            msg.value.getConversionRates(s_priceFeed) >= MIN_USD,
            "You need to spend more ETH."
        ); // 1e18 = 1 * 10 ** 18 = 1000000000000000000
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public payable onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the array
        s_funders = new address[](0);

        //call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;

        // mappings cannot be in memory
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);

        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success, "Call Failed");
    }

    function getOwmer() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConvertor {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        //since this function is going to interact with outside world we will require the ABI and address
        // of that contract.
        // Address = 	0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e (for Goerli Network)
        (, int256 price, , , ) = priceFeed.latestRoundData(); // price if ETH in terms of USD
        return uint256(price * 1e10); // 1**10 == 10000000000
    }

    function getConversionRates(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed); // lets say 3000_000000000000000000 = ETH / USD Price
        // lets say we send 1_000000000000000000 = 1 ETH to this contract
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUSD;
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