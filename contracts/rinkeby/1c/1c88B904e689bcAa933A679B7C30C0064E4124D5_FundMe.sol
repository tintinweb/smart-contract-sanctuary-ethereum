// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// style guides:
// - https://docs.soliditylang.org/en/v0.8.13/style-guide.html
// - https://docs.soliditylang.org/en/v0.8.13/natspec-format.html#natspec

// SPDX-License-Identifier: MIT
// Pragma
pragma solidity ^0.8.0;

// imports
// importing our own library with internal functions
import "./PriceConverter.sol";

// Error Codes
// custom errors -> https://blog.soliditylang.org/2021/04/21/custom-errors/
error FundMe__NotOwner();

// Contracts
/** @title A contract for crowd funding
 * @author Danijel Crepic
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    // Type declarations
    // syntax for using internal functions from our library for uint256
    using PriceConverter for uint256;

    // State variables
    // adding constant keyword -> minimumUsd no longer takes a storage spot and it is much easier to read to(before adding constant we would spend 856277 gas to deploy the contract, after adding constant cost was 836711 - we saved some gas)
    uint256 public constant MINIMUM_USD = 50 * 1e18; // to match 18 decimal places

    // array to keep track of peoples addresses that send us money
    // funders made private, function created getFunders()
    address[] private s_funders; // appending s_ which stands for storage(it will be storage variable)
    // mapping of how much money senders actually send
    // also made private
    mapping(address => uint256) private s_addressToAmountFunded; // appending s_ which stands for storage(it will be storage variable)

    // adding immutable keyword -> before we would spend 23644 gas for calling the i_owner, after we saved on gas which is 21508
    // owner made private, function created getOwner()
    address private immutable i_owner; // appending i_ which stands for immutable(it will not be storage variable)

    // also made private
    AggregatorV3Interface private s_priceFeed; // appending s_ which stands for storage(it will be storage variable)

    // keywords that we can add in a function declaration instead using a require in a function body
    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner");
        // instead of require above we can use custom errors which save some gas
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _; // runs the function code after require passes
    }

    // function that is called right away when contract is deployed
    constructor(address priceFeedAddress) {
        // setting the owner to a person that will deploy the contract
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // What happens if someone sends this contract ETH without calling the fund function?
    // solidity has two special functions for such cases -> receive() and fallback()

    // if somebody will accidentally send money without calling fund function we can still process the transaction by routing them to fund function
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    // public -> anybody can call this function
    // payable -> makes a function payable
    function fund() public payable {
        // Want to be able to set a minimum fund amount in USD
        // 1. How do we send ETH to this contract?
        // https://eth-converter.com/
        // code below changed to code below it as we are using internal functions from our library
        // require(getConversionRate(msg.value) >= minimumUsd, "Didn't send enough"); // to get value that somebody is sending we use msg.value, 1e18 == 1*10**18 == 1000000000000000000 Wei is equal to 1 ETH
        // we don't pass any parameters as msg.value is considered as first passed parameter to the function that expects parameter
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );

        // adding sender to array of senders
        s_funders.push(msg.sender);

        // adding amount to mapping for sender address
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    // function to withdraw funds out of this contract -> should only be called by the owner of this contract
    function withdraw() public onlyOwner {
        // checking if the person that is calling the withdraw function is an owner of the contract, changed to modifier
        // require(msg.sender == owner, "Sender is not owner");

        // once we withdraw the funds we want to reset founders values in our mapping to 0
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        // we also need to reset the funders array -> we are ressteing the array with 0 objects to start in
        s_funders = new address[](0);

        // https://solidity-by-example.org/sending-ether
        // withdraw the funds -> there are three different ways(transfer, send and call)
        // 1. transfer -> msg.sender = address, payable(msg.sender) = payable address
        // transfer will automaticaly revert if the transfer fails
        // payable(msg.sender).transfer(address(this).balance);
        // 2. send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // 3. call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Send failed");
    }

    // creating cheaper withdraw function -> it will use lass gas when writing to memory instead of storage
    function cheaperWithdraw() public payable onlyOwner {
        // creating a copy of s_funders array which will be stored in memory -> cheaper gas when accessing variable stored in memory then storage
        // - https://stackoverflow.com/questions/33839154/in-ethereum-solidity-what-is-the-purpose-of-the-memory-keyword
        address[] memory funders = s_funders;
        // mappings can't be in memory

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
        require(success);
    }

    function getOwner() public view returns (address) {
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

// gas optimization opcodes
// - https://ethereum.org/en/developers/docs/evm/opcodes/
// - https://www.evm.codes/
// - https://github.com/crytic/evm-opcodes

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// imported using instructions from https://docs.chain.link/docs/get-the-latest-price/#solidity
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // function to get a price of ETH in USD -> we need to conect with chainlink data feeds https://docs.chain.link/docs/using-chainlink-reference-contracts/
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // ABI -> whenever we work with a contract we always need ABI and an address
        // Address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e -> https://docs.chain.link/docs/ethereum-addresses/
        // creating new object from imported AggregatorV3Interface
        // commented out as we no longer need to hardcode in the price feed, we will pass an chainlink address as the argument to constructor in FundMe.sol
        // also modified getPrice() and getConversionRate()
        /*
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        */
        // below code modified as we only need the price returned
        // (uint80 roindId, int price, uint startedAt, uint timeStamp, uint80 answeredInRound) = priceFeed.latestRoundData();
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD
        // 3000.00000000
        return uint256(price * 1e10); // 1**10 = 10000000000
    }

    function getVersion() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // get the price of ETH in USD
        uint256 ethPrice = getPrice(priceFeed);
        /*
        example:
        3000_000000000000000000 = ETH / USD price
        1_000000000000000000 ETH -> 1ETH should equeal 3000USD
        */
        // calculate the price of ethAmount in USD
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
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