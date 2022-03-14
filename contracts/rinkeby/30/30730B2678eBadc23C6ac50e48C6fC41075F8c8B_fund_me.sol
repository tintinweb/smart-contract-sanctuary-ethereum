// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// contract for receiving and recording Ether funds with 50 USD minimum, and withdrawing.

// Ethereum data feed https://docs.chain.link/docs/ethereum-addresses/
import "AggregatorV3Interface.sol"; // price rate interface from oracle

abstract contract abstract_fund_me{
    AggregatorV3Interface public price_feed;
    constructor(address _price_feed_address) { // runs at deployment 
        owner = msg.sender; // define "owner" as deployer
        price_feed = AggregatorV3Interface(_price_feed_address);
    }
    mapping(address => uint256) public address_to_payment; // dictionary keeps track of users
    address[] Funders; // not public for anonymous funders
    address public owner; // only set as payable in relevant payable function
    // conversion function to set USD minimum for "fund" function
    function ETH_to_USD(uint256 _ETH_amount) public view virtual returns (uint256 USD_amount);
    function fund(uint256 _minimum) public payable virtual; // "payable" lets caller transfer ether to this deployment address of this contract
    // withdraw and reset funders and payments
    function withdraw() payable public virtual;
    modifier only_owner { // modifier for upcoming "withdraw" function
        require(msg.sender == owner);
        _; // this is where the function code runs. in this case: after "require"
    }
    // abstracted "withdraw" because only implemented function can have modifier
    function withdraw_authorized() payable public virtual only_owner {
        withdraw();
    } // add "owner_only" modifier!
}

contract fund_me is abstract_fund_me {
    // for following https://docs.soliditylang.org/en/latest/contracts.html?highlight=constructor
    constructor(address _price_feed_address) abstract_fund_me(_price_feed_address) {}
    //___________conversion mechanism___________
    // 1 ETH in USD with 18 decimals
    function get_ETH_USD_rate() public view returns (uint256) {
        (, int256 rate,,,) = price_feed.latestRoundData();
        // convert to have 18 decimal places for convenience
        return uint256(rate) * 10 ** (18 - price_feed.decimals());
    }
    // ETH prices in USD with 18 decimals
    function ETH_to_USD(uint256 _ETH_amount) public view override returns(uint256) {
        return _ETH_amount * get_ETH_USD_rate();
    }

    function fund(uint256 _minimum) public payable override {
        require(ETH_to_USD(msg.value)/(10 ** 18) >= _minimum * 10 ** 18, "Insufficient amount."); // msg.value is in Wei so must divide
        address_to_payment[msg.sender] +=msg.value; // update funder total payment
        Funders.push(msg.sender); // record funder address
    }
    
    //___________withdraw mechanism___________
    function withdraw() payable public override {
        // "transfer" sends ETH. "this" keyword refers to current contract.
        // withdraw from deployment address to caller of "withdraw"
        payable(msg.sender).transfer(address(this).balance); // address not payable by default, so recast
        
        // reset payments to zero: run through address array and use mapping
        for (uint256 i=0; i < Funders.length; i++) {
            address_to_payment[Funders[i]] = 0;
        }
        // reset addresses in "Funders" array
        Funders = new address[](0);
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