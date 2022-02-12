// SPDX-License-Identifier: GPL-3.0-or-later

// Solidity version.
pragma solidity ^0.8.0;

// Import chainlink contract in order to get ETH/USD info.
// https://github.com/smartcontractkit/chainlink/tree/develop/contracts
//
// We are importing an interface, check it out at https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
import "AggregatorV3Interface.sol";

// Solidity and math don't get along...This import is not needed beyond version 0.8.
// import safemath

contract FundMe {
    mapping(address => uint256) public addressToAmmountFunded;

    // array of addresses who deposited
    address[] public funders;

    // The one who deploys the contract is it's owner.
    address public owner;

    // Constructor - set the owner.
    constructor() {
        owner = msg.sender;
    }

    // Function that accepts payments.
    function fund() public payable {
        // Let's set minimum value to call fund function.
        // Minimum value is 10$ => How do we know the ETH/USD value?
        // We can't make api calls...it has to be deterministic!
        // How do we keep decentralization?
        // Let's connect with an oracle! (Chainlink) (https://data.chain.link/)

        uint256 minimumUSD = 50 * (10**18);
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "Gimme more ETH!!!"
        );

        // Every contract has this msg.sender/value keywords.
        // msg.sender is the address of the sender that is interacting with the contract.
        // msg.value is the ammount of wei sended by the sender. (1 wei is 10^-18 eth).
        addressToAmmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    // Get version of the chainlink contract.
    function version() external view returns (uint256) {
        // Chainlink has a contract located at the given address.
        // We are going to call the .version() function on that contract.
        // Check values at https://docs.chain.link/docs/ethereum-addresses/
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        return priceFeed.version();
    }

    // Get price with 18 decimals.
    function getPrice() public view returns (uint256) {
        // Get the price feed.
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );

        // Get values of the contract call.
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        return uint256(answer) * (10**10); // 319500841806 => 3,195.00841806 $
    }

    // Convert ethAmmount (in wei => 18 decimals) to USD
    function getConversionRate(uint256 ethAmmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice(); // 18 decimals
        uint256 ethAmmountInUsd = (ethPrice * ethAmmount) / (10**18);
        return ethAmmountInUsd;
    }

    // First run the require and then the code. Check withdraw function.
    modifier onlyOwner() {
        // Only the contract owner can withdraw ETH.
        require(msg.sender == owner, "Only the owner can withdraw!");
        _;
    }

    // Withdrwaw ETH from this contract.
    function withdrwaw() public payable onlyOwner {
        // Sending ETH to the sender from the contract balance.
        payable(msg.sender).transfer(address(this).balance);

        //iterate through all the mappings and make them 0
        //since all the deposited amount has been withdrawn
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmmountFunded[funder] = 0;
        }

        //funders array will be initialized to 0
        funders = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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