// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./PriceConverter.sol";

error FundMe__NotOwner();
error FundMe__NotEnoughtFunds();
error FundMe__CallFailed();

/**
 * @title A contract for crowd funding
 * @author Ben BK
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {

    using PriceConverter for uint256;
    // "constant" saves gaz
    //s_ to say it's a storage variable
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address[] public s_funders;
    mapping(address => uint256) public s_addressToAmountFunded;
    // "immutable" saves gaz
    address public immutable i_owner;

    AggregatorV3Interface public s_priceFeed;

    modifier onlyOwner {
        //require(msg.sender == i_owner, "Not the owner");
        if(msg.sender != i_owner) { revert FundMe__NotOwner(); }
        _;
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //What happens if someone sends this contract ETH without calling the fund function
    // receive() to send a transaction
    receive() external payable {
        fund();
    }

    // fallback() to send datas
    fallback() external payable {
        fund();
    }

    /**
     * @notice This function funds this contract
     */
    function fund() public payable {
        //require(msg.value.getConversionRate() >= MINIMUM_USD, "Didnt't send enought"); // 1e18 = 1 ether
        if(msg.value.getConversionRate(s_priceFeed) < MINIMUM_USD) { revert FundMe__NotEnoughtFunds(); }
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for(uint256 funderIndex = 0 ; funderIndex < s_funders.length ; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the array
        s_funders = new address[](0);
        // withdraw the funds
        // transfer
        //payable(msg.sender).transfer(address(this).balance);
        // send
        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require(sendSuccess, "Send failed");
        // call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        //require(callSuccess, "Call failed");
        if(!callSuccess) { revert FundMe__CallFailed(); }
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        //mappings can't be in memory 
        for(uint256 funderIndex = 0 ; 
            funderIndex < funders.length ; 
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success,) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {

    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint) {
        (,int price,,,) = priceFeed.latestRoundData();
        // ETH in terms of USD
        //Solidity n'a pas de décimales, donc on doit faire des mathématiques pour les obtenir
        return uint256(price * 1e10);
    }


    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
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