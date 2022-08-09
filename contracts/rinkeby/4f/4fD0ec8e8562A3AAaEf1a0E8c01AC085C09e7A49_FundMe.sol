//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./PriceConverter.sol";

error FundMe__notTheOwner();

//interfaces, libraries

/**
 * @title A contract for crowd funding
 * @author Varsha Vijaykumar
 * @notice This contract is for a demo of a sample funding contract
 * @dev This implements price feeds as library
 */

contract FundMe {
    //Type Declarations
    using PriceConvertor for uint256;

    //State Variables
    uint256 public constant MIN_USD = 50 * 1e18; //constant is so that MIN_USD no longer takes up a storage spot.
    // naming convension of constant variables is to be all caps.

    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    address private immutable i_owner; //variables that are set one time outside the variable they are declared are marked immutable.

    //naming convension of immutable variables is that they start with 'i_'.
    //naming convension of storage variables is that they start with 's_'.

    AggregatorV3Interface private s_priceFeed;

    //Modifiers
    modifier onlyOwner() {
        //to make sure a function can only be called by the owner-
        //require(msg.sender == i_owner, " YOU ARE NOT THE OWNER HERE!");

        //for more efficiency, we write this statement-
        if (msg.sender != i_owner) {
            revert FundMe__notTheOwner();
        }

        _; //'_' represents the rest of the code.

        // this code is asking to run require() before '_'.
        // if '_;' was typed above require(...), the require() statement will executed after the code in the respective function.
    }

    //Recieve and Fallback
    // receive() external payable {
    //     fund();
    // }

    // fallback() external payable {
    //     fund();
    // }

    constructor(address s_priceFeedAddr) {
        i_owner = msg.sender; //owner is whoever depoyed this contract.
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddr);
    }

    /**
     * @notice This function finds this contract
     * @dev This implements price feeds as library
     */
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MIN_USD,
            "Didn't send enough!"
        ); // 1e18 == 10^18 wei == 1 eth
        //this has 18 decimal spaces.
        //here getConversionRate() need a parameter but we are not giving it one.
        //this is because msg.value in 'msg.value.getConversionRate()' becomes the 1st parameter of the function getConversionRate().

        s_funders.push(msg.sender);

        //THE FOLLOWING ARE GLOBALLY AVAILABLE VARIABLES AVAILABLE IN SOLIDITY:-
        //  msg.value = amount of ether sent.
        //  msg.sender = address of ether sender.

        //this is a mapping of address of sender to the amount of ether sent.
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        // for(start index, end index, step amount){}
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        //reset the s_funders array.
        s_funders = new address[](0);

        //withdraw funds.

        //There are 3 ways to do this:-
        /*
        //(1) transfer. (if txn fails, returns error) (2300 gas cap)
        payable(msg.sender).transfer(address(this).balance);
        //type of msg.sender -> address.
        //type of payable(msg.sender) -> payable address.

        //(2) send. (if txn fails, returns boolean of txn being unsuccessful) (2300 gas cap)
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess,"Send failed");
        */
        //(3) call. (recommended way for txns)
        (
            bool callSuccess, /*bytes memory dataReturned*/

        ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call Failed");
    }

    //IF SOMEBODY ACCIDENTALLY SENDS MONEY WITHOUT CALLING 'FUND', THESE 2 FUNCTIONS WILL REDIRECT THEM TO THE FUND FUNCTION.

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        //reset the s_funders array.
        s_funders = new address[](0);

        //withdraw funds.
        (
            bool callSuccess, /*bytes memory dataReturned*/

        ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call Failed");
    }

    //make i_owner visible
    function getOwner() public view returns (address) {
        return i_owner;
    }

    //make s_funders visible
    function getFunders(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    //make s_addressToAmountFunded visible
    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    // make s_priceFeed visible
    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConvertor {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        //the address below is from site:- https://docs.chain.link/docs/ethereum-addresses/
        //ETH / USD addr = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e (Rinkby Testnet).

        (, int256 price, , , ) = priceFeed.latestRoundData();
        //latestRoundData() returns a lot of things and we want only 1 value.
        //The rest of the them are just denoted by commas.
        //this returns price of eth in USD.
        //the returned value will have 8 decimal spaces.

        return uint256(price * 1e10); //10^10

        //we use uint256(...) to typecase to uint256.
    }

    // function getVersion() internal view returns (uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(
    //         0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    //     );
    //     return priceFeed.version();
    // }

    function getConversionRate(uint256 ethAmt, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmtInUSD = (ethPrice * ethAmt) / 1e18;
        return ethAmtInUSD;
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