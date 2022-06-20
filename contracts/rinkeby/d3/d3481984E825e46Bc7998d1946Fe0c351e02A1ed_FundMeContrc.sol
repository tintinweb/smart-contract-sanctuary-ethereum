//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "AggregatorV3Interface.sol";

contract FundMeContrc {
    mapping(address => uint256) public AddressToFunds;

    address owner;
    address[] public funders;

    function fundMe() public payable {
        uint256 minFunding = 50 * 10**18; //$50 for min fudning amount
        require(
            convertEth_USD(msg.value) >= minFunding,
            "Funding must be more than $50"
        );
        AddressToFunds[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface version = AggregatorV3Interface(
            address(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e)
        );
        return version.version();
    }

    function getUSDPrice() public view returns (uint256) {
        AggregatorV3Interface USDPrice = AggregatorV3Interface(
            address(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e)
        );
        (, int256 answer, , , ) = USDPrice.latestRoundData();
        return uint256(answer * 10000000000);
        //Why does the price come in x10^8, shouldnt it be gwei which is x10^9?
    }

    function convertEth_USD(uint256 _EthPrice) public view returns (uint256) {
        uint256 EthPrice = (getUSDPrice() * _EthPrice) / 1000000000000000000;
        return EthPrice;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "You must be owner to withdraw the funds");
        _;
    }

    function withdrawFunds() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 _index = 0; _index < funders.length; _index++) {
            address funder = funders[_index];
            AddressToFunds[funder] = 0;
        }
        funders = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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