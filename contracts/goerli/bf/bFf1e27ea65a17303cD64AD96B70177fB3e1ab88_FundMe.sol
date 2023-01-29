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

pragma solidity ^0.8.8;
import "./PriceConverter.sol";

error FundMe__NotOwner();

/**
 * @title A contract for crowd funding
 * @author DEV Sumon
 * @notice this contract is demo a simple funding contract 
 * @dev this implements price feeds our library
*/

contract FundMe {
    using PriceConverter for uint;
    // 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    //storage variabele
    uint public constant minimumUSD = 50 * 10 ** 18;
    address private immutable owner;

    // event Funded(address indexed from, uint amount);

    address[] private fundersArray;
    mapping(address => uint) private addressToAmount;
   
    AggregatorV3Interface private priceFeed;

    modifier onlyOwner() {
        if (msg.sender != owner) revert FundMe__NotOwner();
        _;
    }

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // receive() external payable {
    //     fund();
    // }

    // fallback() external payable {
    //     fund();
    // }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= minimumUSD,
            "Eth not enough to send"
        ); // 1e18 = 1 * 10 ** 18 = 1000000000000000000 wei
        addressToAmount[msg.sender] += msg.value;
        fundersArray.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        for (
            uint funderIndex = 0;
            funderIndex > fundersArray.length;
            funderIndex++
        ) {
            address funder = fundersArray[funderIndex];
            addressToAmount[funder] = 0;
        }
        fundersArray = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess);
    }
    // function cheaperWithdraw() public onlyOwner {
    //     address[] memory funders = funders;
    //     // mappings can't be in memory, sorry!
    //     for (
    //         uint256 funderIndex = 0;
    //         funderIndex < funders.length;
    //         funderIndex++
    //     ) {
    //         address funder = funders[funderIndex];
    //         addressToAmount[funder] = 0;
    //     }
    //     funders = new address[](0);
    //     // payable(msg.sender).transfer(address(this).balance);
    //     (bool success, ) = owner.call{value: address(this).balance}("");
    //     require(success);
    // }

    // public view pure funtion declearation
    function getAddressToAmountFunded(address fundingAddress) public view returns(uint){
        return addressToAmount[fundingAddress];
    }
    function getFunder(uint index) public view returns(address){
        return fundersArray[index];
    }
    function getOwner() public view returns(address){
        return owner;
    }
    function getPriceFeed() public view returns(AggregatorV3Interface){
        return priceFeed;
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // gorerli 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeed);
        (/* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/) = priceFeed.latestRoundData();
        return uint(price * 1e10);
    }
    // function getVersion() internal view returns(uint) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    //     return priceFeed.version();
    // }
    function getConversionRate(uint ethAmount,AggregatorV3Interface priceFeed) internal view returns(uint) {
        uint ethPrice = getPrice(priceFeed);
        uint ethAmountUsd = (ethPrice * ethAmount) / 1e18 ;
        return ethAmountUsd;
    }
}