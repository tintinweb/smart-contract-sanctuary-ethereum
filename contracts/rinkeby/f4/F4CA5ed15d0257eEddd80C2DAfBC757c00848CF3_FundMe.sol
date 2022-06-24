// SPDX-License-Identifier: MIT
// 1. Pragma
pragma solidity ^0.8.0;
// 2. Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

// 3. Interfaces, Libraries, Contracts
error FundMe__NotOwner();

/**@title A sample Funding Contract
 * @author Patrick Collins
 * @notice This contract is for creating a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    // Type Declarations
    using PriceConverter for uint256;

    // State variables
    uint256 public constant MINIMUM_USD = 50 * 10**18;
    address private immutable i_owner;
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;

    // Events (we have none!)

    // Modifiers
    modifier onlyOwner() {
        // require(msg.sender == i_owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
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

    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
        i_owner = msg.sender;
    }

    /// @notice Funds our contract based on the ETH/USD price
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function withdraw() public payable onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // Transfer vs call vs Send
        // payable(msg.sender).transfer(address(this).balance);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function cheaperWithdraw() public payable onlyOwner {
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
    function getAddressToAmountFunded(address fundingAddress)
        public
        view
        returns (uint256)
    {
        // several getters, we don't people who interact with our code
        // to have to deal with the s_ strage stuff
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
}


// pragma solidity ^0.8.8;

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// import "./PriceConverter.sol";

// error FundMe__NotOwner();

// //NATSPEC
// /**@title A sample Funding Contract
//  * @author Patrick Collins
//  * @notice This contract is for creating a sample funding contract
//  * @dev This implements price feeds as our library
//  */
// contract FundMe {

//     // Type declarations
//     using PriceConverter for uint256;

//     // state variables
//     mapping(address => uint256) public s_addressToAmountFunded;
//     address[] public s_funders;

//     // Could we make this constant?  /* hint: no! We should make it immutable! */
//     address public /* immutable */ i_owner;
//     uint256 public constant MINIMUM_USD = 5 * 10 ** 18;

//     AggregatorV3Interface public s_priceFeed;

//     modifier onlyOwner {
//         // require(msg.sender == owner);
//         if (msg.sender != i_owner) revert FundMe__NotOwner();
//         _;
//     }
    
//     constructor(address priceFeedAddress) {
//         i_owner = msg.sender;
//         s_priceFeed = AggregatorV3Interface(priceFeedAddress); //depend on whatever chain we are on
//     }

//     receive() external payable {
//         fund();
//     }

//     fallback() external payable {
//         fund();
//     }

//     /**
//     * @notice This function fund this conract
//     * @dev This implements price feeds as our library
//     */
//     function fund() public payable {
//         require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
//         //msg.value is considered as the first parameter of getConversionRate()
//         // if we had in the library function add(uint x, uint y)
//         // we would have written x.add(y)
//         // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
//         s_addressToAmountFunded[msg.sender] += msg.value;
//         s_funders.push(msg.sender);
//     }
    
   
    
//     function withdraw() payable onlyOwner public {
//         for (uint256 funderIndex=0; funderIndex < s_funders.length; funderIndex++){
//             address funder = s_funders[funderIndex];
//             s_addressToAmountFunded[funder] = 0;
//         }
//         s_funders = new address[](0);
//         // transfer the fund to whoever is calling the withdraw function
//         // // transfer
//         // payable(msg.sender).transfer(address(this).balance);
//         // // send
//         // bool sendSuccess = payable(msg.sender).send(address(this).balance);
//         // require(sendSuccess, "Send failed");
//         // call
//         //(bool callSuccess, bytes memory dataReturn) = payable(msg.sender).call{value: address(this).balance}("");
//         (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
//         require(callSuccess, "Call failed");
//     }

//     function cheaperWithdraw() public payable onlyOwner {
//         address[] memory funders = s_funders;
//         // mappings can't be in memory, sorry!
//         for (
//             uint256 funderIndex = 0;
//             funderIndex < funders.length;
//             funderIndex++
//         ) {
//             address funder = funders[funderIndex];
//             s_addressToAmountFunded[funder] = 0;
//         }
//         s_funders = new address[](0);
//         // payable(msg.sender).transfer(address(this).balance);
//         (bool success, ) = i_owner.call{value: address(this).balance}("");
//         require(success);
//     }

//     /** @notice Gets the amount that an address has funded
//      *  @param fundingAddress the address of the funder
//      *  @return the amount funded
//      */
//     function getAddressToAmountFunded(address fundingAddress)
//         public
//         view
//         returns (uint256)
//     {
//         return s_addressToAmountFunded[fundingAddress];
//     }

//     function getVersion() public view returns (uint256) {
//         return s_priceFeed.version();
//     }

//     function getFunder(uint256 index) public view returns (address) {
//         return s_funders[index];
//     }

//     function getOwner() public view returns (address) {
//         return i_owner;
//     }

//     function getPriceFeed() public view returns (AggregatorV3Interface) {
//         return s_priceFeed;
//     }

// }

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Why is this a library and not abstract?
// Why not an interface?
library PriceConverter {
    // We could make this public, but then we'd have to deploy it
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // https://docs.chain.link/docs/ethereum-addresses/
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }

}