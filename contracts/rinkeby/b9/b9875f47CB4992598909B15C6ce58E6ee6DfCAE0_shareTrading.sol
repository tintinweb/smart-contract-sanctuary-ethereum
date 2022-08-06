//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
 import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
    import "./converter.sol";

contract shareTrading{
    using converter for uint256;

    uint256 public priceOfEachShare= 50*10*18; //5000 gwei
   
    address []public purchaserOfShares;
    mapping (address=>uint256) public mappingAddresses;
    address public owner;
    mapping (address=>uint256)public balances;
    AggregatorV3Interface public priceFeed;
  

    constructor (address priceFeedAddress){
        owner=msg.sender;
        balances[owner]= 10000;
        priceFeed= AggregatorV3Interface(priceFeedAddress);
    }
    modifier onlyOwner (){
        _;
        require (msg.sender==owner, "error");
    }

    function buyShares( uint256 _totalShares, address recipient)public payable {
       
    
        require (msg.value>=priceOfEachShare, "You need to bid higher");
        //need something to multiply shares*price of one share
        
      
        require (balances[msg.sender]>=_totalShares);
        require (balances[msg.sender]- _totalShares<=balances[msg.sender]);
        require(balances[recipient]+ _totalShares>=balances[recipient]);
        balances[msg.sender]-=_totalShares;
        balances[recipient]+=_totalShares;
      
        purchaserOfShares.push(msg.sender);
        mappingAddresses[msg.sender]= msg.value;

    }
   
   
    function withdraw()public onlyOwner{
        for (uint256 i=0; i<purchaserOfShares.length; i++){
            address purchaser= purchaserOfShares[i];
            mappingAddresses[purchaser]= 0;
        }
        purchaserOfShares= new address[](0);

        (bool callSuccess, )= payable(msg.sender).call{value:address(this).balance}("");
        require (callSuccess, "Not valid");
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
 import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
library  converter {
     function getPrice(AggregatorV3Interface priceFeed)public view returns (uint256) {
    (, int price,,,)= priceFeed.latestRoundData();
    return uint256 (price*1000000000);
}
    function getConversionRate(AggregatorV3Interface priceFeed, uint256 maticAmount) public view returns (uint256) {
        uint256 maticPrice= getPrice(priceFeed);
        uint256 maticInUSD= (maticAmount*maticPrice)*1000000000000000000;
        return maticInUSD;
    }
    
}