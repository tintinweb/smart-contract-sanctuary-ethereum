// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
//Imports

//To get the right conversion to use
//divide the number u want to fund by current price of eth by  and convert to wei

//50/ 1313 
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

//State Variable
contract PiggyBank {
 using PriceConverter for uint256;

address payable public owner;
uint256 public USD = 10*10**18;
AggregatorV3Interface public priceFeed;

constructor(address priceFeedAddress) {
    priceFeed = AggregatorV3Interface(priceFeedAddress);
    owner == msg.sender;
}

modifier onlyOwner() {
    require(msg.sender == owner, "Not Owner");
    _;
}

function depositFund() public payable {
 require(msg.value.getConversionRate(AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e))>= USD, "add more Eth");


}

function withdrawFund(address _to, uint _amount) external onlyOwner {
    (bool success, ) = _to.call{value: _amount}("");
    require(success, "having issues with transaction at this time");
}

function getVersion() external view returns(uint256) {
    // ETH/USD price feed address of Goerli Network.

    AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    return priceFeed.version();
}
 function destroyContract(address payable _to) external onlyOwner {
     selfdestruct(_to);


 }

function getBalalnce() external view returns(uint256) {
    return address(this).balance;
}



}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Why is this a library and not abstract?
// Why not an interface?
library PriceConverter {
    // We could make this public, but then we'd have to deploy it
    function getPrice(AggregatorV3Interface priceFeed) public view returns (uint256) {
        // Goerli ETH / USD Address
        // https://docs.chain.link/docs/ethereum-addresses/
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
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
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.
        return ethAmountInUsd;
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