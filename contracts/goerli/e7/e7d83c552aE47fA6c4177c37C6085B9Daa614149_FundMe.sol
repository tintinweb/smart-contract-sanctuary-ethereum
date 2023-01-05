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

pragma solidity 0.8.17;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error NotOwner();
contract FundMe{
    address immutable i_owner;
    constructor(){
        i_owner = msg.sender;
    }
    modifier checkOwner{
        if(i_owner != msg.sender){ revert NotOwner();}
        _;
    }
    uint public constant MINIMUM_USD = 0.1*1e18;
    address[] public funders;
    mapping(address => uint) public senders;
    function getLatestPrice() public view returns(uint){
        AggregatorV3Interface pricefeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        (,int price,,,) = pricefeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function fund() public payable{
        require(getConversionRate(msg.value) >= MINIMUM_USD, "Hey pay more");
        funders.push(msg.sender);
        senders[msg.sender] += msg.value;
    }

    function getConversionRate(uint ethAmount) public view returns(uint){
        uint ethPrice = getLatestPrice();
        uint ethAmountinUsd = (ethAmount * ethPrice);
        return ethAmountinUsd;
    }
    function withdraw(address addr) public checkOwner{
        // require(msg.sender == owner, "Not owner");
        for(uint funderI = 0; funderI < funders.length; funderI++){
            address funder = funders[funderI];
            senders[funder] = 0;
        }
        funders = new address[](0);

        //withdraw


        //transfer
        // payable(msg.sender).transfer(address(this).balance); // gas limit - 2300 and real transaction limit 21000wei -> revert

        //send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance); same as transfer return bool
        // require(sendSuccess, "Failed");

        //call
        (bool callSuccess,) = payable(addr).call{value: address(this).balance}("");
        require(callSuccess, "Failed");


        //fallback // recieve
    }
    receive() external payable{
        fund();
    }
    fallback() external payable{
        fund();
    }

}