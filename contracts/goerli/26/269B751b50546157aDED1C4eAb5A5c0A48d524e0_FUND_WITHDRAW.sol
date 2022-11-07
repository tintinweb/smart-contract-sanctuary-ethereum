// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./PriceConverter.sol";

contract FUND_WITHDRAW
{
    using PRICE_CONVERTER for uint;

    uint public constant min_USD = 25 * 1e18; //constant keyword with variables that dont update or change 
    address[] public Funders_Address;         //in contract reduces gas consumption. It is used with variables
    mapping (address => uint) public Search_Amount; //declare and initialized in same line.

    function FUND() public payable
    {
        require( msg.value.getconversion_USD(PRICE_FEED) >= min_USD, "INVALID AMOUNT! SEND MORE :)");
        Funders_Address.push(msg.sender);
        Search_Amount[msg.sender] = msg.value.getconversion_USD(PRICE_FEED);
    } 

    address internal immutable OWNER; //immutable keyword with variables that dont update or change 
                                // throughout contract but are initialized in a different line or func.
    AggregatorV3Interface internal immutable PRICE_FEED; 
    constructor(address priceFeedaddress)                      
    {
        OWNER = msg.sender;
        PRICE_FEED = AggregatorV3Interface(priceFeedaddress)  ;                   //Since constructor code runs as soon as contract is deployed so at
    }                       // that time msg.sender will be the deployer of contract

    function WITHDRAW()public payable
    {
        require ( msg.sender == OWNER, "YOU ARE NOT THE OWNER!"); //check for owner only otherwise revert

        //resetting mapping
        for (uint index = 0; index < Funders_Address.length; index++)
        {
            address temp = Funders_Address[index];
            Search_Amount[temp] = 0;
        }
        //resetting array
        Funders_Address = new address[](0);

        //withdrawing using call
        (bool call_success, ) = payable (msg.sender).call{value: address(this).balance}("");
        require ( call_success, "ERROR!");

    }

    // If someone funds contract without using FUND() or funding externally to the contract.
     receive() external payable
    {
        FUND();   //receive() will trigger if the external transaction has no input data along value
    }
    fallback() external payable
    {
        FUND();   //receive() will trigger if the external transaction has input data along vlaue
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PRICE_CONVERTER
{
    
 function getprice_Of_ETH( AggregatorV3Interface Price_Feed ) internal view returns (uint) //we want uint in return as msg.value is uint
    {
        (,int answer,,,) = Price_Feed.latestRoundData();
        return uint(answer * 1e10);  //answer will have 8 decimal place and we want 18
    }

    function getconversion_USD( uint Eth_amount, AggregatorV3Interface PriceFeed ) internal view returns (uint)
    {
        uint ETHinUSD = (getprice_Of_ETH(PriceFeed) * Eth_amount) / 1e18;
        return ETHinUSD;

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