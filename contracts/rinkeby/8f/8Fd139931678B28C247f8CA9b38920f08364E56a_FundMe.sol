// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";

error NotOwner();

//error появились с версии 0.8.4

contract FundMe {
    using PriceConverter for uint256; // позволяет привязывать методы библиотеки к типу данных ( uint256.ourMethod() ), при этом первым параметром будет само число

    uint256 public constant MINIMUM_USD = 0.5 * 1e18; // 0.5$, число с 18 нулями
    //constant экономит газ тк переменная не занимает память
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;
    //immutable для переменных которые сетим один раз, экономит газ, название по конвенции начинается с "i_"

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // payable для отправки токенов
        require(
            msg.value.getConversionRate(priceFeed) > MINIMUM_USD, // getConversionRate первый параметр это всегда число с которым мы работаем, то что передаем вручную уже будет вторым параметром
            "Didn't send enough!"
        ); // 1e18 = 1 * 10 ** 18 = 1000000000000000000 = 1 Eth
        //18 decimals (wei)
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        // применение нашего модификатора, модификаторы выполняются в первую очередь до выполнения функции
        for (uint256 funderIndex; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0); // reset array

        /*
            3 способа:

            transfer(2300 gas, throws error)
            send(2300 gas, returns bool)
            call(forward all gas or set gas, returns bool)
        */
        //transfer
        // payable(msg.sender).transfer(address(this).balance); // address(this) - текущий контракт, transfer при ошибке кинет ошибку и закончит функцию
        //         //payable() - typecasting, обертка над адресом
        // bool sendSuccess = payable(msg.sender).send(address(this).balance); // при ошибке вернет false, и код ниже выполнится
        // require(sendSuccess, "Send failed");
        // (bool callSuccess, bytes memory dataReturned) => payable(msg.sender).call{value: address(this).balance}(""); // так же возвращает данные в ответе
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }(""); // call рекомендуемый способ
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        // модификатор для функции
        // require(msg.sender == i_owner, "Sender is not owner");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        // использование кастомных ошибок вместо require экономит газ, тк текстк ошибки в require это массив букв что требует память
        _; // нижнее подчеркивание обозначает выполнения остального кода функции
    }

    // modifier onlyOwner() { // модификатор для функции
    //     _;
    //     require(msg.sender == owner, "Sender is not owner");
    // } // здесь наоборот, сначала выполнения кода функции а затем модификатора

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    //в библиотеках нельзя создавать глобальные переменные и слать токены
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        //address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e адрес контракта chailink eth/usd rinkeby для получение цены эфира

        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // ); // для доступа к контрактам в сети используем адрес контракта обернутый в его интерфейс
        (, int256 price, , , ) = priceFeed.latestRoundData(); // () = деструктуризация, функция latestRoundData возвращает несколько переменных
        //ETH to USD price
        return uint256(price * 1e10); //1 * 10 ** 10 = 10000000000, в функции fund мы работает с 18 decimal, price возвращает 8 decimals, поэтому степень 10-и, т.е из числа с 8 нулями сделать число с 18-ю
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUSD;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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