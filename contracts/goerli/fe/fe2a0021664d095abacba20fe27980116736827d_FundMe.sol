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
//pragma
pragma solidity >=0.4.22 <0.9.0;

//import "hardhat/console.sol";
//console.log atabilmek için, jsdekiyle aynı çalışır

//imports
import "./PriceConverter.sol";

//error codes
error FundMe__NotOwner();
//stringle hata mesajı vermek fazla gaz harcar o yüzden error döndürmek daha mantıklı
//contract adını daha açık olabilmek için yazdık

//Interfaces, Libraries


//alttakiler normal insanın anlayacağı şekilde açıklama yapmak için
/**
 * @title A contract for crowd funding
 * @author d
 * @notice this contract is to demo a sample funding contract
 * @dev this implements price feeds as our library
 */

//contracts
contract FundMe {
    //Type Declarations
    using PriceConverter for uint256;
    //bunun sayesinde tipi uint256 olanlarla fonku metod şeklinde kullanabilirsin
    //bu olmasaydı normal fonk şeklinde de kullanılabilirdi


    //State Variables
    uint256 public constant MINIMUM_USD = 50;
    //constant ve immutable değiştirilemez, sabit anlamına gelir ve daha az gaz harcar
    //IMMUTABLE CONSTRUCTOR'DA TANIMLANIR CONSTANT DİREKT YANINA YAZILIR
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    //modifier
    modifier onlyOwner {
        //require(msg.sender == i_owner, "sender is not owner!");
        if(msg.sender != i_owner) { revert FundMe__NotOwner(); }
        //yukarıdakiyle aynı anlama geliyor, daha az gaz harcar ve yeni bir yöntem
        _;
        //_; kodu yürüt demek, üste koysaydık önce withdrawı yürütür sonra require'a bakardı
    }


    //FUNCTIONS ORDER
    //constructor
    //receive
    //fallback
    //external
    //public
    //internal
    //private
    //view/pure

    constructor(address s_priceFeedAddress){
        //sözleşme ilk çalıştırıldığında bu en başta çalışır
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddress);
    }

    //biri yanlışlıkla fonk çağırmadan para gönderirse
    /*receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }*/
    //bu yöntemler doğrudan funda basmaktan daha pahalı
    //ama direkt funda yönlendirdikleri için normal işlemle aynı sayılırlar

    //BİR HATAYLA KARŞILAŞIRSAN:
    //15-20 dakika üzerinde düşün ve çözmeye çalış, aklına gelen bütün çözümleri denediğinden emin ol
    //1. hatanın ne olduğunu anlamaya çalış ve çözmeyi dene
    //2. google'da arat


    /**
     * @notice this function funds this contract
     * @dev this implements price feeds as our library
     */
    //param, return gibi şeyler de var
    function fund() public payable {
        //payable kırmızı buton yapar, para yatırmak için
        require(msg.value.getConversionRate(s_priceFeed) > MINIMUM_USD, "Didn't send enough!"); //1e18 == 1 * 10 ** 18 == 100...
        //require kontrol ediyor, msg.value deployun üzerindeki value değeri için
        //gönderdiğin para yetersizse o yere gelene kadarki gazı harcayıp kalanını sana geri verir
        s_funders.push(msg.sender);
        //gönderenin adresini diziye atmak için
        s_addressToAmountFunded[msg.sender] = msg.value;
        //gönderen ve ne kadar gönderdiğini görmemiz için
    }

    function withdraw() public onlyOwner{
        //modifier eklenince fonktan hemen sonra gidip oraya bakıyor
        for(uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        //arrayi resetlemek için
        s_funders = new address[](0);
        //başlangıçta 0 elemanı olan dizi oluşturuldu

        //transfer 
        //msg.sender adres döndürür, payable tipine değiştirdik
        payable(msg.sender).transfer(address(this).balance);
        //transfer build in, contracttan hesaba para göndermek için
        //address(this) contract adresini belirtiyor


        //send
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");
        //transferde aksilik olduğunda direkt iptal olur, sendde kontrol edebilirsin


        //call
        (bool callSucces, ) = payable(msg.sender).call{value: address(this).balance}("");
        //call bool döndürüyor, value da ikinci parametrenin değerini veriyor
        //("") yerine fonk konabilir ama gerek duymadık
        require(callSucces, "call failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        //bir şeyi storage'den okumak pahalıya gelir, o yüzden memory olarak atıp memory olarak çağırdık aşağıda
        //sürekli storage'den getirmek çok maliyetli olur
        address[] memory funders = s_funders;
        //minimumda bir hesaptan para çekilir. normal withdraw'a göre minimum daha pahalı burada çünkü
        //üstteki satır artı olarak çalıştırılır, bu yukarıda olmaz
        //çoklu hesapta burada tasarruf var
        for(
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ){
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }
    //state variable'ları public yaparsak daha fazla gaz harcar, görüntülemek için onları private yapıp bu fonkları yazdık
    //bunlar herkesin her an görmesi gerekmeyen bilgiler, gerekirse bu fonkları çağırabilirler
    function getOwner() public view returns(address){
        return i_owner;
    }
    function getFunder(uint256 index) public view returns(address) {
        return s_funders[index];
    }
    function getAddressToAmountFunded(address funder) public view returns(uint256) {
        return s_addressToAmountFunded[funder];
    }
    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
     function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256) {
            //ABI
            //Address 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
            //AggregatorV3Interface priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
            //address contract adresi, her zincirde farklı adres olur. yukarıda da bir contract adresi oluşturulmuş
            (,int256 answer,,,) = priceFeed.latestRoundData();
            return uint256(answer * 10000000000); //inti uinte dönüştürmek için
            //usd'yi wei gibi elde etmek için çarptı, 8 sıfırı zaten vardı o yüzden 10la çarpmak gerekiyordu
            //böylece 3k dolar 1 ethere eşit olacak
        }

        function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
            //diğer tarafta metod gibi kullanacaksan parametrede uint256 diye belirtmen lazım
            uint256 ethPrice = getPrice(priceFeed);
            // 1 eth 3k usdye eşit olacak
            uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
            return ethAmountInUsd;
        }
}