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
pragma solidity ^0.8.17;
// ilk compile yaparken hata vericek 
// çünkü bizim bu priceconverter da olan importu gerçekten yüklemedik yüklicez onu
// "yarn add --dev @chainlink/contracts"


import "./PriceConverter.sol";
 
error NotOwner();
contract FundMe{
  using PriceConverte for uint256; 
  
  uint256 public  constant MINIMUM_USD = 10 * 1e18;
  address[] public funders; 
  
  mapping(address => uint256) public addressToAmountFunded; 
 
  address public  i_owner;
  // price feed yazdık 
  AggregatorV3Interface public priceFeed;
  constructor(address priceFeedAdress){
    i_owner = msg.sender;
    priceFeed = AggregatorV3Interface(priceFeedAdress);
    }
  

  function fund()public payable {  
  // ve buraya pricefeed girmemiz gerekiyor 
    require(msg.value.getConversionRate(priceFeed)  >= MINIMUM_USD, "Did not send enough");  
    funders.push(msg.sender); 
    addressToAmountFunded[msg.sender] += msg.value; 
  }

  function withdraw() public onlyOwner {
    

   
    for(uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
      
      address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0; 
    } 
      funders = new address[](0);
    
    (bool callSuccess,) = payable(msg.sender).call{value : address(this).balance}(""); 
    require(callSuccess,"Call Failed");
  }
     
    

    

     
    

    modifier onlyOwner{
      require(msg.sender == i_owner, "Sender is NOT owner");
      
      _;
       
    }
    
    



receive() external payable{
  fund();
}

fallback() external payable{
  fund();
}













    
   

  
  




}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
// şimdi bu kütüphaneler kodları düzenlemek içinde var diyebiliriz biz oradaki tüm fiyat çevirme fonklarını buraya atacağız ve public özelliğini
// interval yapmalıyız ki kullanabilelim
// ve bunlarda şu var herhangi bir durum değişkeni bildiremezsiniz ve eter gönderemezsiniz yani aslında bunları contract olarak yazmayacaksın 
// kodların karışmaması için iyi 

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
library PriceConverte{
    function getPrice(AggregatorV3Interface priceFeed) public view returns(uint256) { 
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e); artık bunu ullanmamıza gerek kalmadı
        // bazı parametreleri değiştirdik
        (,int256 price ,,,) = priceFeed.latestRoundData();
        return uint(price*1e10); 
   }
  //  biz buradaki addresi değiştirmek istemiyoruz o yüzden onu parametreleştiricez çünkü başka bir testnete geçince oradaki kontrat adını yazmamız lazım
  // bunu fund dosyasındaki constructora priceFeed adresini parametre atayarak başlayacağız sonrasında
      

  //  artık buna da gerek yok 

  //  function getVersion()internal view returns(uint256){
  //    AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
  //    return priceFeed.version(); 
  //  }
   function getConversionRate(uint256 ethAmount,AggregatorV3Interface priceFeed) internal view returns (uint256){
     uint256 ethPrice = getPrice(priceFeed);   
 
     uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
     return ethAmountInUsd;
   }
  

}