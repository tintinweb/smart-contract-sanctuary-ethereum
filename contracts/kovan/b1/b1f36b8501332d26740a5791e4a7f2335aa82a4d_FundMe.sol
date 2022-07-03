/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
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
contract FundMe {
    // This key word is use to make librairies execute themselves on types.
    // Here it is to very overflow issues
    // using SafeMathChainlink for uint256;

    address public owner;
    address[] public funders;

    constructor() {
        owner = msg.sender;
    }

    // to keep track of who has sent us money
    mapping(address => uint256) public senderAddressToAmountSent;

    // the keyword payable make the function accept payments
    function fund() public payable {
        // We want to filter funds to only ones which are greater than 50 dollars
        uint256 minimumUSD = 10 * 10**18;

        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You are a rat, give me more !"
        );
        // msg.sender and msg.value are key word that goes with any transaction or contract calls
        senderAddressToAmountSent[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    // conversion 1 eth = 10^18 Wei and & eth = 10^8 Gwei so 1 Gwei = 10^10 Wei

    // If we want to work with an other currency such as USD or EURO, How can we do ?
    /* Because the conversion rate is not written in the blockchain we need to retrieve this data offchain
       That is why Oracles such as Chainlink exists. 
    */

    // To learn how to interact with interfaces we have imported let create a function
    function getVersion() public view returns (uint256) {
        // This address is refering to the smart contract which has the value of conversion rate in it.
        /* 
            Kovan ETH->USD 0x9326BFA02ADD2366b30bacB125260Af641031331
            Rinkeby ETH->USD 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        */
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        return priceFeed.version();
    }

    // Now we can try to retreive the current conversion rate
    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // In order to get every return value in the smallest unit of eth which is Wei and as answer is in Gwei
        // we need to multiply by 10**10.
        return uint256(answer * 10**10);
    }

    function getConversionRate(uint256 _ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (_ethAmount * ethPrice) / 10**18;
        return ethAmountInUSD;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);

        // reset the mapping
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funderAddress = funders[funderIndex];
            senderAddressToAmountSent[funderAddress] = 0;
        }
        // reset the array
        funders = new address[](0);
    }
}