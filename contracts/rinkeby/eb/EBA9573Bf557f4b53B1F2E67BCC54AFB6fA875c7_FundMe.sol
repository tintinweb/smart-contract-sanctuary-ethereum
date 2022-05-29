// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "MiniConverter.sol";

contract FundMe {
    uint256 lastFundValue;
    address lastFundAddress;

    address public owner;
    mapping(address => uint256) fundersMapping;
    address[] public funders;

    uint256 randomNumber;

    address priceFeeAddress;

    constructor(uint256 randomNumberWhileConstructing, address price_fee_adr)
        public
    {
        owner = msg.sender;
        lastFundValue = 0;
        lastFundAddress = 0x0000000000000000000000000000000000000000;
        randomNumber = randomNumberWhileConstructing;
        priceFeeAddress = price_fee_adr;
    }

    function getRandomNumber() public view returns (uint256) {
        return randomNumber;
    }

    function fund() public payable {
        lastFundValue = msg.value;
        lastFundAddress = msg.sender;
        fundersMapping[lastFundAddress] += lastFundValue;
        if (!contains(funders, lastFundAddress)) funders.push(lastFundAddress);
    }

    function fundTestWEI() public payable {
        //ovo moze samo ako posalje vise od 500 WEI-a.
        require(msg.value > 500, "You dont pay much, ha?");
    }

    function fundTest5Dollars() public payable {
        //Kako mozemo da proverimo.
        //Ocemo da posaljemo npr 8.95 USD-a. To dalje konvertujemo u ETH, sto je 0.005ETH-a,
        //Sada 0.005ETH-a konvertujemo u Wei-e, i to prosledimo u VALUE gde ce valuta biti Wei.
        uint256 minimumUSD = 5;
        uint256 minimumUSDWEI = minimumUSD * 10**18;

        MiniConverter mc = new MiniConverter(priceFeeAddress);
        require(
            mc.getConversionRate(msg.value) > minimumUSDWEI,
            "Not enought WEIs"
        );
    }

    function withdrawFunds() public payable {
        require(msg.sender == owner, "You are not owner!");
        msg.sender.transfer(address(this).balance);
        resetFunders();
        resetFundersMapping();
        resetLastFundAddress();
        resetLastFundValue();
    }

    function getContractBallance() public view returns (uint256) {
        return address(this).balance;
    }

    function getLastFundValue() public view returns (uint256) {
        return lastFundValue;
    }

    function getLastFundAddress() public view returns (address) {
        return lastFundAddress;
    }

    function getNumberOfFunders() public view returns (uint256) {
        return funders.length;
    }

    function resetLastFundValue() private {
        lastFundValue = 0;
    }

    function resetLastFundAddress() private {
        lastFundAddress = 0x0000000000000000000000000000000000000000;
    }

    function resetFunders() private {
        funders = new address[](0);
    }

    function resetFundersMapping() private {
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            fundersMapping[funder] = 0;
        }
    }

    function contains(address[] memory addressArray, address addr)
        private
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < addressArray.length; i++) {
            address adrCurr = addressArray[i];
            if (adrCurr == addr) return true;
            else continue;
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "AggregatorV3Interface.sol";

contract MiniConverter {
    // 1 ETH = 1000000000 GWei = 1000000000000000000 Wei
    //https://docs.chain.link/docs/ethereum-addresses/

    AggregatorV3Interface public aV3i;

    constructor(address aV3i_priceFee_address) public {
        aV3i = AggregatorV3Interface(aV3i_priceFee_address);
    }

    function getEtheriumPriceUSD() public view returns (uint256) {
        (, int256 answer, , , ) = aV3i.latestRoundData();
        return uint256(answer);
    }

    function getEtheriumPriceUSD18Decimals() public view returns (uint256) {
        (, int256 answer, , , ) = aV3i.latestRoundData();
        return uint256(answer * 10000000000);
        //answer ima 8 decimala i dodaju mu se 10.
    }

    //1,749.59037262 USD   ---Broj decimala se dobija funkcijom decimals. Trenutno je 8 decimala.

    function getConversionRate(uint256 weiAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPriceInUSD = getEtheriumPriceUSD18Decimals();
        uint256 ethAmountInUSD = (ethPriceInUSD * weiAmount) /
            1000000000000000000;
        return ethAmountInUSD;
    }

    //1768922030540 je izlaz. Ali treba nam 18 decimala.
    //0.000001768922030540 USD  --- Ovoliko kosta 1 GWei tj 1000000000 Wei-a

    function getDecimals() public view returns (uint256) {
        return aV3i.decimals();
    }

    function getEurToUSD(uint256 eurAmount) private view returns (uint256) {
        (, int256 answer, , , ) = aV3i.latestRoundData();
        return uint256(uint256(answer) * eurAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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