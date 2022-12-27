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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";     //in PriceConverter.sol already we have chainlink AggregatorV3Interface file so we need not to import it

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    
    event Funded(address indexed from, uint256 amount);

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address public owner;
    uint256 public constant MINIMUM_USD = 50 * 10 ** 18;
    
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
        emit Funded(msg.sender, msg.value);
    }
    
    modifier onlyOwner {
        // require(msg.sender == owner);
        if (msg.sender != owner){ 
            revert NotOwner();    //throwing the error
        }
        _;
    }
    
    function withdraw() public onlyOwner {
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        // // transfer
        payable(msg.sender).transfer(address(this).balance);
        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // call
        // (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        // require(callSuccess, "Call failed");
    }

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
}

// Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \ 
    //         yes  no
    //         /     \
    //    receive()?  fallback() 
    //     /   \ 
    //   yes   no
    //  /        \
    //receive()  fallback()

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/*
interface AggregatorV3Interface{
    //interfaces compile down to an ABI.The ABI tells solidity and other programming languages how it can interact with
    //another contract.(application binary interface)

    function decimals() external view returns(uint8);
    function description() external view returns(string memory);
    function version() external view returns(uint256);

    function getRoundData(uint80 _roundId) external view returns(uint80 rountId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredIdRound);
    function latestRoundData() external view returns(uint80 rountId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredIdRound);
}
*/

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // Goerli ETH / USD Address
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
        // or (Both will do the same thing)
        // return uint256(answer * 1e10); // 1* 10 ** 10 == 10000000000
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // or (Both will do the same thing)
        // uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; // 1 * 10 ** 18 == 1000000000000000000
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }
}