//SPDX-License-Identifier: MIT
//pragma
pragma solidity ^0.8.0;
//imports
import "./PriceConvertor.sol";
//error codes
error FundMe__NotOwner();

contract FundMe {
    //constant and immutable
    using PriceConvertor for uint256;
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address private immutable i_Owner;
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeedAddress) {
        i_Owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function Fund() public payable {
        //we mark it with payable if the function is pay able with any currency like etherium
        //set minimum fund amount
        require(
            msg.value.getConversionRates(s_priceFeed) >= MINIMUM_USD,
            "Not enough funds"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for (uint256 i = 0; i < s_funders.length; i++) {
            address funder = s_funders[i];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        //https://solidity-by-example.org/sending-ether/
        //transfer- simplest  it will throw an error if gas price is higher and will automatically revert the transaction
        // payable(msg.sender).transfer(address(this).balance);

        //send- it will give boolean false if gas price is higher or true if transaction is successful
        //bool sendsuccess=payable(msg.sender).send(address(this).balance);
        //require(sendsuccess,"send failed");- will revert the transaction

        //call
        (bool callSuccess /*bytes memory dataReturned*/, ) = payable(msg.sender)
            .call{value: address(this).balance}(""); //.call is used to call any function in any other contract so we leave it blank
        // to use it as a transaction we give {}
        require(callSuccess, "call failed");
    }

    modifier onlyOwner() {
        //require(msg.sender==i_Owner,"Sender is not owner");
        if (msg.sender != i_Owner) {
            revert FundMe__NotOwner();
        }
        _; // states that fir  st check the require statement and then the rest of the statements in the function
        // if _; is specofoed above the require statement then it would first execute the function and then will check the require statement
    }

    //https://solidity-by-example.org/sending-ether/

    //recieve and fallback are used if some sender sends ether to contarct and does not used fund function
    //receive is used when there is no msg.data else fallback is used
    receive() external payable {
        //
        Fund();
    }

    fallback() external payable {
        Fund();
    }

    function getOwner() public view returns (address) {
        return i_Owner;
    }

    function getFunders(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddresstoAmountFunded(
        address funder
    ) public view returns (uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getPricefeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConvertor {
    function getConversionRates(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUSD = (ethAmount * ethPrice) / 1e18; //divide by 1e18 as ethAmount and price have 18 deciaml places and so ti will go to 36 0's places if we dont divide
        return ethAmountInUSD;
    }

    // function getVersion(AggregatorV3Interface priceFeed) internal view returns (uint256) {
    //    // https://docs.chain.link/data-feeds/price-feeds/addresses

    //     return priceFeed.version();
    // }

    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        //abi
        //address 0x694AA1769357215DE4FAC081bf1f309aDC325306

        (
            ,
            /* uint80 roundID */ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }
}