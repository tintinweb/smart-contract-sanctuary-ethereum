//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./priceConverter.sol";

contract FundMe {
    using priceConverter for uint256;

    uint256 public minimumUSD = 50 * 1e18; // 1 * 10 ** 18
    address[] public Funders;

    mapping(address => uint256) public addrs_toamount_track;

    address public owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function Fund() public payable {
        require(
            //1st_Arg...................(2nd_Arg)
            msg.value.getConvertionRate(priceFeed) >= minimumUSD,
            "Didn't send enough eth "
        );
        Funders.push(msg.sender);
        addrs_toamount_track[msg.sender] += msg.value;
    }

    function withdraw() public Onlyyowner {
        // require(msg.sender == owner,"Only owner can  call this function");
        /*starting index; ending index; step amount*/
        for (
            uint256 funderindex = 0;
            funderindex < Funders.length;
            funderindex += 1
        ) {
            address fundersagain = Funders[funderindex];
            addrs_toamount_track[fundersagain] = 0;
        }
        // reset the array
        Funders = new address[](0);
        (bool callsuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callsuccess, "Call failed");
    }

    modifier Onlyyowner() {
        require(msg.sender == owner, "only owner can call this function");
        _;
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