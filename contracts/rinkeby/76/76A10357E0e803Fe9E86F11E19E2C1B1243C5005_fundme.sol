// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./priceconverter.sol";

error notowner();

contract fundme{
    using priceconverter for uint256;
    address[] public funders;
    mapping(address => uint256) public fundedamount;
    address public /* immutable */ owneraddress ;
    uint256 public eth_usd;
    uint256 public minusd=50*1e18;
    address public pricefeedaddress;
    constructor(address pricefeed){
        pricefeedaddress=pricefeed;
        owneraddress=msg.sender;
    }
    function fund ( )  public payable{

        require(msg.value.getconvert(pricefeedaddress)>minusd,"not allowed");

        funders.push(msg.sender);
        fundedamount[msg.sender]+=msg.value;
    }


    modifier onlyowner
    {
        if (msg.sender!=owneraddress)
        {
            revert notowner();
        }
        _;
    }

    function withdraw() public onlyowner payable{
        for (uint256 funder=0 ;funder < funders.length; funder++)
        {
            address add=funders[funder];
            fundedamount[add]=0;

        }
        funders=new address[](0);

        //payable (msg.sender).transfer(address (this).balance);

        // bool success =payable (msg.sender).send(address (this).balance);
        // require(success,"unsuccessful transaction!");


        //most recommended to transfer ether 
        (bool success,) =payable (msg.sender).call{value: address (this).balance}("");
        require(success,"unsuccessful transaction!");


    }
    receive() external payable{
        fund();
    }

    fallback() external payable{
        
        fund();

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library priceconverter{
    function price (address pricefeedaddress)  internal view returns(uint256)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(pricefeedaddress);
        (,int val,,,)=priceFeed.latestRoundData();
        return uint (val*1e8);
    }
    function getconvert(uint256 amount,address pricefeedaddress) internal view  returns(uint256)
    {
        uint pr=price(pricefeedaddress);
        uint256 v;
        v=(amount*pr)/1e18;
        return v;
    }
}