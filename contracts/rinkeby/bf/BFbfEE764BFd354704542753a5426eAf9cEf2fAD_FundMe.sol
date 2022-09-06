//SPDX-License-Identifier: MIT
//pragma
pragma solidity ^0.8.0;
//imports
import "./priceConverter.sol";
//Error Codes
error FundMe__NotOwner();

//Interfaces,   Libraries,  Contract

//NATSPEC

/** @title A contract for crowd funding
 * @author  Omar
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price Feeds as our library
 
 */
contract FundMe {
    // Type Declarations
    using priceConverter for uint256;

    // State declaration or variable
    uint256 public constant MINIMUM_USD = 50 * 1e18; // 1 * 10 ** 18
    address[] private s_Funders;
    mapping(address => uint256) private s_addrs_toamount_track;
    address private immutable i_owner;
    AggregatorV3Interface public s_priceFeed;

    modifier Onlyyowner() {
        // require(msg.sender == owner, "only owner can call this function");
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    // Functions Order:
    /// constructor
    /// receive
    /// fallback
    /// external
    /// public
    /// internal
    /// private
    /// view / pure

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    receive() external payable {
        Fund();
    }

    fallback() external payable {
        Fund();
    }

    function Fund() public payable {
        require(
            //1st_Arg...................(2nd_Arg)
            msg.value.getConvertionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough eth "
        );
        s_Funders.push(msg.sender);
        s_addrs_toamount_track[msg.sender] += msg.value;
    }

    function withdraw() public payable Onlyyowner {
        // require(msg.sender == owner,"Only owner can  call this function");
        /*starting index; ending index; step amount*/
        for (
            uint256 funderindex = 0;
            funderindex < s_Funders.length;
            funderindex += 1
        ) {
            address fundersagain = s_Funders[funderindex];
            s_addrs_toamount_track[fundersagain] = 0;
        }
        // reset the array
        s_Funders = new address[](0);
        (bool callsuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callsuccess, "Call failed");
    }

    function cheaperWithdraw() public payable Onlyyowner {
        address[] memory funders = s_Funders;
        //mappings can't be in memory,sorry!
        for (
            uint256 funderindex = 0;
            funderindex < funders.length;
            funderindex++
        ) {
            address funder_again = funders[funderindex];
            s_addrs_toamount_track[funder_again] = 0;
        }
        s_Funders = new address[](0);
        (bool callsuccess, ) = i_owner.call{value: address(this).balance}("");
        require(callsuccess, "call failed");
    }

    // view and pure func
    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_Funders[index];
    }

    function getAddresstoamountTrack(address funder)
        public
        view
        returns (uint256)
    {
        return s_addrs_toamount_track[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library priceConverter {
    function getprice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD
        // 3000.00000000
        return uint256(price * 1e10); //  1**10 == 10000000000 => 3000.000000000000000000
    }

    //  .......................1st arg           ,  2ndArg
    function getConvertionRate(
        uint256 ethamount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethprice = getprice(priceFeed);
        uint256 ethamountInUSD = (ethprice * ethamount) / 1e18;
        return ethamountInUSD;
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