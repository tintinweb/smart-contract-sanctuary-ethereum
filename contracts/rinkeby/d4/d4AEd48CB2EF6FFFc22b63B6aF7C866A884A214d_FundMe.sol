//SPDX-License-Identifier: MIT
// Pragma first
pragma solidity ^0.8.7;

// Import 2nd
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

// Error codes 3rd this is the name convention ContractName__ErrorCode
error FundMe__notOwner();
error FundMe__notSent();

// Interface 4th, libraries 5th and contracts 6th

/**
 * @title A contract for crowdfunding
 * @author Wesley Pigny
 * @notice This is a demo of a funding contract
 * @dev This implements price feed as our library
 */
contract FundMe {
    // Type declarations 1st
    using PriceConverter for uint256;

    // State variables 2nd
    // constant, immutable variable
    // Declaring constants and immutable instead of normal variables reduces the gas cost of the contract.
    address[] private s_funders;
    uint256 private constant MINIMUM_USD = 50 * 1e18;
    address private immutable i_owner;
    uint256 private s_nbFunders = 0;
    uint256 private s_ticket = 0;

    mapping(address => uint256) private s_funderToTicket;
    mapping(address => uint256) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;

    // Modifiers 3rd
    /**
     * @notice Modifier to allow only the owner to call the functions
     */
    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not owner");
        // Reduce the gaz fee of the contract
        if (msg.sender != i_owner) {
            revert FundMe__notOwner();
        }
        _;
    }

    // Set the owner of the contract
    /**
     * @notice Constructor sets the owner of the contract and the price feed
     */
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // Functions fallback and receive 4th
    /**
     * @notice Fallback and receive function executes fund function
     */
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    // Normal functions 5th
    /**
     * @notice Fund function allows to fund the contract
     */
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
        s_nbFunders++;
        createTicket();
    }

    /**
     * @notice creates a s_ticket based on the address of the funder
     * @dev The s_ticket is incremented for each funder and start at 0
     */
    function createTicket() public {
        s_ticket += 1;
        s_funderToTicket[msg.sender] = s_ticket;
    }

    /**
     * @notice Allow owner to withdraw the funds of the contract
     * @dev Check if this is the owner with onlyOwner modifier
     */
    function withdraw() public onlyOwner {
        for (uint256 i; i < s_funders.length; i++) {
            // Reset the balance of each funder to 0 in the mapping
            address funder = s_funders[i];
            s_addressToAmountFunded[funder] = 0;
            s_funderToTicket[funder] = 0;
        }
        //Reset the array
        s_funders = new address[](0);
        s_nbFunders = 0;
        s_ticket = 0;
        //Withdraw the funds using call
        //transfer, send, call are 3 differents ways to send money
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        // require(sent, "Not sent");
        if (!sent) {
            revert FundMe__notSent();
        }
    }

    /**
     * @notice Allow owner to withdraw the funds of the contract (cheaper version)
     * @dev Check if this is the owner with onlyOwner modifier
     */
    function cheaperWithdraw() public onlyOwner {
        address[] memory funders = s_funders;

        // Mappings can't be in memory...
        for (uint256 i; i < funders.length; i++) {
            // Reset the balance of each funder to 0 in the mapping
            address funder = funders[i];
            s_addressToAmountFunded[funder] = 0;
            s_funderToTicket[funder] = 0;
        }

        s_funders = new address[](0);
        s_nbFunders = 0;
        s_ticket = 0;

        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        // require(sent, "Not sent");
        if (!sent) {
            revert FundMe__notSent();
        }
    }

    // Getters, View functions
    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getNbFunders() public view returns (uint256) {
        return s_nbFunders;
    }

    function getTicket() public view returns (uint256) {
        return s_ticket;
    }

    function getFunder(uint256 _index) public view returns (address) {
        return s_funders[_index];
    }

    function getAddressToAmountFunded(address _address)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[_address];
    }

    function getFunderToTicket(address _funder) public view returns (uint256) {
        return s_funderToTicket[_funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 18;
        return ethAmountInUsd;
    }
}