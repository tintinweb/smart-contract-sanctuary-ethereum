// SPDX-License-Identifier:MIT

pragma solidity ^0.6.10;

import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addresToAmount;
    address public owner;
    address[] public funders;
    AggregatorV3Interface priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        //payable function is used to transform a function to one that can be used pay
        //msg.sender = address of sender
        //msg.value = the value or the amount sent by the sender

        uint256 minAmount = 5 * 10**18;
        require(
            ethToUSD(msg.value) >= minAmount,
            "The minimum amount you can send is 5 USD"
        );

        addresToAmount[msg.sender] += msg.value;
        funders.push(msg.sender); //Adds address of whoever funded the contract
    }

    function getVersion()
        public
        view
        returns (
            uint256,
            string memory,
            uint8
        )
    {
        return (
            priceFeed.version(),
            priceFeed.description(),
            priceFeed.decimals()
        );
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        // In the above line, the commas indicate that some return variable is there but we assign it as blank as we don't want that particular return type and we want only int256 answer from the function call

        return uint256(answer * 10**10);
    }

    function ethToUSD(uint256 _amount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmount = (_amount * ethPrice) / (1000000000000000000);

        return ethAmount;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can withdraw!");
        _;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);

        /* The below code resets the funders array and the addressToAmount mapping as the whole amount is withdrawn*/
        for (
            uint256 fundersIndex = 0;
            fundersIndex < funders.length;
            fundersIndex++
        ) {
            address funder = funders[fundersIndex];
            addresToAmount[funder] = 0;
        }

        funders = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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