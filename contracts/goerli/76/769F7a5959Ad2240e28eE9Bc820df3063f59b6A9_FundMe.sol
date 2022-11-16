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

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./PriceConverter.sol";

// interface AggregatorV3Interface {
//     function decimals() external view returns (uint8);

//     function description() external view returns (string memory);

//     function version() external view returns (uint256);

//     function getRoundData(uint80 _roundId)
//         external
//         view
//         returns (
//             uint80 roundId,
//             int256 answer,
//             uint256 startedAt,
//             uint256 updatedAt,
//             uint80 answeredInRound
//         );

//     function latestRoundData()
//         external
//         view
//         returns (
//             uint80 roundId,
//             int256 answer,
//             uint256 startedAt,
//             uint256 updatedAt,
//             uint80 answeredInRound
//         );
// }

// get funds from users
// withdraw funds
// set minimum funding value in usd

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    // making gas efficient by using constant
    //23471 uint256 public MINIMUM_USD = 50 * 1e18;
    //21415
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    // gas efficient with immutable stores dictly in bytecode rather than storage
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // for sending token function should be payable
    function fund() public payable {
        // want to able to send minimum fund in usd
        // How to send ETH to this contract
        // msg.value in Eth so need oracles for conversion
        // require(
        //     getConversionRate(msg.value) > minimumUsd,
        //     " Didn't send enough"
        // );
        //here msg.value considered as first parameter and if have many then pass explicitly
        require(
            msg.value.getConversionRate(priceFeed) > MINIMUM_USD,
            " Didn't send enough"
        );
        // 1e18= 1* 10**18 => 1000000000000000000 in gwei
        // reverting
        //  undo the action before and send remaining gas back
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    // function getPrice() public view returns (uint256) {
    //     // ABI
    //     // Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    //     // AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e).version();
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(
    //         0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    //     );
    //     (, int256 answer, , , ) = priceFeed.latestRoundData();
    //     // answer is price of eth in terms of usd
    //     // 3000.00000000
    //     return uint256(answer * 1e10); // 1e10= 10000000000
    // }

    // function getVersion() public view returns (uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(
    //         0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    //     );
    //     return priceFeed.version();
    // }

    // function getConversionRate(uint256 ethAmount)
    //     public
    //     view
    //     returns (uint256)
    // {
    //     uint256 ethPrice = getPrice();
    //     uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
    //     return ethAmountInUsd;
    // }

    function withdraw() public onlyOwner {
        // require(msg.sender == owner,"Sender is not owner");
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // reset the array
        funders = new address[](0);

        // actually withdraw the funds
        // transfer
        // msg.sender = address
        // payable(msg.sender) = payable address
        // payable(msg.sender).transfer(address(this).balance);
        // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // call
        // (bool callSuccess, uint256 memory dataReturned)=payable(msg.sender).call({value:address(this).balance}(""));
        // call is recommended way
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner");
        if (msg.sender != i_owner) {
            revert NotOwner(); // custom error
        }
        _; //tells like execute rest of the code
    }

    // wat happens if omeone sends some eth wwithout calling fund function
    // there are 2 methods to handle this receive and fallback

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // ABI
        // Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e).version();
        //In mocking it is commented
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // answer is price of eth in terms of usd
        // 3000.00000000
        return uint256(answer * 1e10); // 1e10= 10000000000
    }

    // function getVersion() internal view returns (uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(
    //         0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    //     );
    //     return priceFeed.version();
    // }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}