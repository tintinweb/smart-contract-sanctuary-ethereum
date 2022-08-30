// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "./PriceConvertor.sol";

error NotOwner();

contract FundMe {
    using PriceConvertor for uint256;

    uint256 public number;

    uint256 public constant MINIMUM_USD = 50 * 1e18; // We have to keep the uints same everywhere
    // When we are comparing the values in sendUsd function, we are comapring msg.value coming from getConversionPrice function
    // which has 18 decimal points so we have to convert our dollar price in 18 decimal points as well
    address[] public funders;
    mapping(address => uint256) public funderAmount;
    AggregatorV3Interface priceFeed;
    address public immutable i_owner;

    constructor(address priceFeedAddress) {
        // When the contract is deployed, the msg.sender in that case will be the owner of the contract.
        // So we can save the value of owner in constructor.
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function sendTest() public payable {
        number = 5;

        // Here if require statement is not met, the number will be reverted back to 0 and you have to pay gas for this
        // and remaining gas will be sent back

        // Want to send minimum amount in Ether

        // What is reverting, undo any action and send remaining gas back

        require(msg.value > 1e18, "Didn't send enough");
        // 1e18 is one ETH
    }

    function sendUsd() public payable {
        // here the numberUsd is 50 $ which needs to be compared with 1 ETH
        // We need to get the price of one ether in terms of USD to compare
        // Blockchain cannot interact with external systems that is why we have to use Decentralized oracle network

        require(
            msg.value.getConversionPrice(priceFeed) > MINIMUM_USD,
            "Didn't send enough"
        );

        // msg.value returns ETH in terms of wei which has 18 decimal points
        // convert msg.value from layer 1 / ETH to USD
        // The msg.value depends on what blockchain we are working with, it can be ETH, Avalanche or polygon

        funders.push(msg.sender);
        funderAmount[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funderAddress = funders[funderIndex];
            funderAmount[funderAddress] = 0;
        }

        // Resetting an array, the 0 here defines how many elements will be there in an array to start with.

        funders = new address[](0);

        // msg.sender = address
        // payable(msg.sender) = payable address

        // withdraw the funds to an address

        // transfer, if this send fails it will just return error and return transaction
        //payable(msg.sender).transfer(address(this).balance);

        // send, if this send passes it will return boolean
        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // This require states if sendSuccess is true then continue executing the lines else display the error
        //require(sendSuccess,"Transfer Failed!!");

        //call, we can use this function to call any function in ethereum without an ABI
        // In paranthesis we define which function we want to call in ethereum network
        // we can leave it blank by inputting double quotes
        //(bool txnSuccess, bytes memory dataReturned) = payable(msg.sender).call{value: address(this).balance}("");

        (bool txnSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(txnSuccess, "Transfer Failed!!");
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        //require(msg.sender == i_owner,"Sender is not owner!!");
        // This _ means that the above line will be executed first and then all the code writtern in the function
        // will be executed to which this modifier has been applied.
        _;
    }

    // What happens if someone sends this contract ETH directly ?

    receive() external payable {
        sendUsd();
    }

    fallback() external payable {
        sendUsd();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConvertor {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // To get price of eth in terms of USD we have to interact with oracle databases outside our blockchain
        // We will use a interface here to get the price of ETH in terms of USD
        // To interact with outside contracts or interfaces we need ABI and address which we can get from docs.chain.link
        // https://docs.chain.link/docs/ethereum-addresses/ and choose the network that you are on rinkeby, kovan
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x9326BFA02ADD2366b30bacB125260Af641031331
        // );

        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // Price that came in answer has 8 decimal points so we are adding 10 more decimal points to answer because we
        // have to compare it with ETH value which is in terms of wei which has 18 decimal points
        return uint256(answer * 1e10);
    }

    // function getDecimal() internal view returns (uint8) {
    //     AggregatorV3Interface decimalFeed = AggregatorV3Interface(
    //         0x9326BFA02ADD2366b30bacB125260Af641031331
    //     );
    //     return decimalFeed.decimals();
    // }

    // function getVersion() internal view returns (uint256) {
    //     AggregatorV3Interface versionFeed = AggregatorV3Interface(
    //         0x9326BFA02ADD2366b30bacB125260Af641031331
    //     );
    //     return versionFeed.version();
    // }

    function getConversionPrice(
        uint256 ethValue,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 priceOfUsdInEth = getPrice(priceFeed);
        // 2 Eth * (Value of 1 eth in usd)
        // Because both values have 18 decimal points when we multiply them it will give us 36 decimal points
        // so we are dividing it with 1**18 decimal points
        uint256 convertedValue = (ethValue * priceOfUsdInEth) / 1e18;
        return convertedValue;
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