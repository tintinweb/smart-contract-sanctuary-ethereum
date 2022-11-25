/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

//SPDX-License-Identifier: MIT
// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


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

// File: .deps/FundMikeStuff/LibPriceConversion.sol


pragma solidity ^0.8.8;


library LibPriceConversion
{

    //Функция для получения актуальной цены эфира через оракул.
    function GetPrice() internal view returns (uint256)
    {

        AggregatorV3Interface priceAggregator = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);


        ( ,int256 answer, , , ) = priceAggregator.latestRoundData();
        
        return uint256(answer * 1e10);

    }

    //Функция для определения значения value (в данном контексте, суммы, которую хотят задонатить)
    //в долларовом эквиваленте.
    function GetConversionRate(uint256 donateValue) internal view returns (uint256)
    {
        
        uint256 ethPrice = GetPrice();
        uint256 ethPriceInUSD = (ethPrice * donateValue) / 1e18;

        return ethPriceInUSD;

    }

}
// File: .deps/FundMikeStuff/FundMike.sol


pragma solidity ^0.8.8;


error NotMike();
error NotDev();
error YouHaveNoAccess();


contract FundMike
{
    using LibPriceConversion for uint256;


    address public immutable devAddress;
    address public constant mikeAddress = 0xffb88D354AaE6D4a26131154223143d66086eaD8;
    address[] public funders;
    mapping (address => uint256) funderToAmount;
    uint256 public minimumUSDAmount;

    constructor() //функция вызывается при деплое.
    {

        devAddress = msg.sender;
        funders.push(msg.sender);

        ChangeMinimumFundAmount(10);


    }


    //Функция для отправки доната.
    function Fund() public payable
    {
        
    
        require(msg.value.GetConversionRate() >= minimumUSDAmount, "The amount you want to donate is lower than minimum donate amount.");
        HandleFundersList(msg.sender, msg.value);

        
    }


    //Функция для обновления массива с адресами донатеров
    function HandleFundersList(address funderAddress, uint256 donatedAmount) internal
    {

        //проходимся по массиву
        //если дона с таким адресом еще не было - записываем его в массив и в маппинг
        //если таковой был - обновляем сумму доната в маппинге

        uint256 fundersCounter = 0;

        for (uint256 funder = 0; funder < funders.length; funder++)
        {
            


            if(funderAddress == funders[funder])
            {

                funderToAmount[funders[funder]] = funderToAmount[funders[funder]] + donatedAmount;
                break;
            }
            else
            {

                fundersCounter++;

            }

        }

        if(fundersCounter == funders.length)
        {

            funders.push(funderAddress);
            funderToAmount[funderAddress] = donatedAmount;

        }

    }

    
    //функция для проверки баланса контракта.
    function ShowBalance() public isDevOrMike view returns(uint256)
    {

        return uint256(address(this).balance);

    }

    //функция для получения списка донов.
    function RetrieveFundersListAdresses() public isDevOrMike view returns (address[] memory)
    {

        return funders;

    }


    function ShowMinimumDonateAmount() public view returns(uint256)
    {

        return minimumUSDAmount;

    }

    //функция для изменения минимальной суммы доната.
    function ChangeMinimumFundAmount(uint256 newAmount) public isDevOrMike
    {

        minimumUSDAmount = newAmount * 1e18;

    }



    //функция для вывода крипты на адрес mikeAddress.
    function Withdraw()  public isMike
    {

        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require (callSuccess, "Can't withdraw.");

    }

    //функция вызывается при отправке транзакции при условии, что нет обращения к функциям
    //или параметрам контракта 
    receive() external payable 
    {                          

        Fund();

    }


    //тоже при отправке транзакции вызывается, даже если было обращение к функции\параметру
    fallback() external payable
    {

        Fund();

    }

    modifier isMike
    {
        if(msg.sender != mikeAddress)
        {
            revert NotMike();
        }
        _;
    }

    modifier isDev
    {

        if(msg.sender != devAddress)
        {

            revert NotDev();
            
        }
        _;

    }

    modifier isDevOrMike
    {

        if(msg.sender == mikeAddress || msg.sender == devAddress)
        {

            _;

        }
        else
        {

            revert YouHaveNoAccess();

        }


    }

}