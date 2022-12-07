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
pragma solidity ^0.8.0;
import "./PriceConverter.sol";

contract FundMe {
    using PriceConverter for uint256;

    // constant variables == variabili che non vengono piu cambiate, si scrivono in MAIUSC
    // immutable == variabili che vengono cambiate 1 sola volta, si indicano con un i_ prima del nome
    uint constant MINIMUM_USD = 50;
    mapping(address => Funder) public fundersMapping;
    address[] public funders;
    address public immutable i_owner;

    struct Funder {
        address _address;
        uint amountFounded;
    }

    AggregatorV3Interface public priceFeed;

    // priceFeed ci serve per cambiare automaticamente i indirizzi dei contratti per non farlo manualmente
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fundMe() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Not enough money"
        );
        Funder memory newFounder = Funder({
            _address: msg.sender,
            amountFounded: msg.value
        });
        fundersMapping[newFounder._address] = newFounder;
        funders.push(msg.sender);
    }

    modifier checkOwner() {
        require(
            i_owner == msg.sender,
            "Only the owner can withdraw the function"
        );
        _;
    }

    function withdraw() public checkOwner {
        /*index di inizio, index di fine, cosa fare quando si raggiunge ogni index*/
        for (uint funderIndex; funderIndex < funders.length; funderIndex++) {
            // Prendiamo funder tramite index
            address funder = funders[funderIndex];
            // Settiamo il bilancio a zero
            fundersMapping[funder].amountFounded = 0;
        }
        // Reset Array
        funders = new address[](0);

        // withdraw funds
        // dobbiamo inviare i eth dati ad un indirizzo, abbiamo 3 modi per farlo:
        // transfer (costo del gas: 2300, se ce un errore lo dispone)
        //payable(msg.sender).transfer(address(this).balance); // this == questo contratto && (this).balance == bilancio di questo contratto
        // send (costo del gas: 2300, ritorna un boolean sullo stato della transazione)
        //(bool status) = payable(msg.sender).send(address(this).balance);
        //require(status == true, "An error accured");
        // call
        (bool callStatus, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callStatus == true, "An error accured");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // Da il valore di eth in usd
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // ABI: Lista di funzioni di un contratto che possiamo eseguire
        // Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        (, int256 price, , , ) = priceFeed.latestRoundData(); // = ETH in USD
        return uint256(price * 1e10);
    }

    // Converte i eth in usd
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // Ci da il prezzo dei eth in usd
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUSD;
    }
}