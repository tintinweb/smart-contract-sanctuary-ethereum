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

//Get Fund From Users
//WithDraw Funds
//Set A minimum Funding Value in USD

//SPDX-License-Identifier: MIT

//Prama
pragma solidity ^0.8.17; // You can use other version See Slides for more info
//Imports

/* interface AggregatorV3Interface {                     // We are importing it by Link because this a an                                                   //
  function decimals() external view returns (uint8);    // an ugly practice

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
    } */

import "./PriceConverter.sol";

//error code

// Constant, immutable
//	841840 gas
//  822310 gas
//-------------
//error FundMe__Noti_owner();// for revert use which is ga efficient

/**@title A sample Funding Contract
 * @author EngrSaeedWazir
 * @notice This contract is for creating a sample funding contract
 * @dev This implements price feeds as our library
 */

contract FundMe {
    //type Declaration //styeguide
    using PriceConverter for uint256;
    //uint256 public number; // For Now Commented it

    //	21371 gas, for constant in view function
    //23,400 gas , for non-constant in view function

    //State variables //styeguide
    mapping(address => uint256) private s_addressToAmountFunded; // map to specific address
    address[] private s_funders; // All the addreses who funded

    address private immutable i_owner; //a global variable
    uint256 public constant MINIMUM_USD = 50 * 1e18; //1*10**18

    // 21508 gas, immutable
    //23644 gas, without immutable
    AggregatorV3Interface private s_priceFeed;

    // Events (we have none!)

    // Modifiers
    modifier onlyowner() {
        require(msg.sender == i_owner, "Sender is not i_owner"); //Noti_owner());
        //if(msg.sender !=i_owner){revert FundMe__Noti_owner();}
        _;
    }

    // Functions Order:
    //// constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    /// @notice Funds our contract based on the ETH/USD price
    function Fund() public payable {
        //Want to be able to Send a minimum fund amount in USD
        //1.  How do we send ETH to this conaract
        //number=5;  // For Now Commented it
        //require(msg.value > MINIMUM_USD, "Donot Send Enough");

        //require(getConversionRate(msg.value) >= MINIMUM_USD, "Donot Send Enough"); //1e18 == 1*10**18= 1000000000000000000
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        ); //value paramter pass to function in Library

        //a Ton of computation
        // What is Reverting
        //Undo any action before, and send ramaining gas back
        s_funders.push(msg.sender); // sender address
        s_addressToAmountFunded[msg.sender] += msg.value; // how much a specific adress send
    }

    function Withdraw() public onlyowner {
        //require(msg.sender == i_owner, "Sender is not i_owner");/*May be other function in this contract need
        // this rquire statement therefore our focus is modifier.                                                        //
        /*starting index, ending index, step amount */
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        //reset the address
        s_funders = new address[](0);
        // actually withdraw the fund

        /*
      // transfer
      payable(msg.sender).transfer(address(this).balance);   // Call is used today so comment the other
      // send
      bool sendSuccess=payable(msg.sender).send(address(this).balance);
      require(sendSuccess, "Send failed"); */

        //call
        (bool callSuccess /* byte memory storedata */, ) = payable(msg.sender)
            .call{value: address(this).balance}("");
        require(callSuccess, "Send failed");

        //msg.sender=address
        //payable(msg.sender)=payable address
        //payable(msg.sender).transfer(address(this).balance);
    }

    function cheaperWithdraw() public onlyowner {
        address[] memory funders = s_funders;
        // mappings can't be in memory, sorry!
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // payable(msg.sender).transfer(address(this).balance);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    /** @notice Gets the amount that an address has funded
     *  @param fundingAddress the address of the funder
     *  @return the amount funded
     */
    function getAddressToAmountFunded(
        address fundingAddress
    ) public view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

    // what happen if some one send eth without calling the fund function
    // recieve()
    //fallback()
    // receive() external payable {
    //     Fund();
    // }

    // fallback() external payable {
    //     Fund();
    // }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17; // You can use other version See Slides for more info

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        //ABI
        //Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );
        (, int256 price, , , ) = priceFeed.latestRoundData(); // /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
        // ETH in term of USD
        // 1,218.00000000
        return uint256(price * 10000000000); //1**10=10000000000
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        return priceFeed.version();
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000; //// 1 * 10 ** 18 == 1000000000000000000=1e18 //36 zeros but we want 18 zeros
        return ethAmountInUsd;
    }
}