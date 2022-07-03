//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./PriceConverter.sol";

error NotOwner(); //vedi sezione errori di manual.sol

contract FundMe {
    using PriceConverter for uint256; //utilizzo questa libreria per tutti gli uint256

    uint256 public constant minimumUSD = 50;

    address[] public funders; //lista di donatori
    mapping(address => uint256) public addressToAmount; //mappa donatori con quanto hanno donato

    address public immutable owner;
    AggregatorV3Interface public priceFeed;

    /*
        Poiché il costruttore viene chiamato solo ed esclusivamente nel momento
        in cui il contratto viene pubblicato, msg.sender sarà uguale all'indirizzo della persona
        che lo sta pubblicando, quando accederanno le altre persone msg.sender sarà diverso dal
        proprietario e il costruttore non verrà più chiamato.
    */
    constructor(address priceFeedAddress) {
        owner = msg.sender; //msg.sender = indirizzo della persona che sta pubblicando il contratto
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //richiedere fondi all'utente
    function fund() public payable {
        //dobbiamo impostare un valore minimo in USD

        //require(getConversionRate(msg.value) >= minimumUSD * 1e18, "Non hai pagato abbastanza"); //1e16 è espresso in Wei
        require(
            msg.value.getConversionRate(priceFeed) >= minimumUSD * 1e18,
            "Non hai pagato abbastanza"
        );
        funders.push(msg.sender); //msg.sender = account che chiama la funzione
        addressToAmount[msg.sender] += msg.value;
    }

    //preleva tutti i fondi raccolti nel contratto e azzera la lista e la mappa di donatori
    /*
        Questa funzione non può però essere chiamata da chiunque, ma solo da chi possiede 
        il contratto. Vedi sopra la risluzione del problema(costruttore).
    */
    function withdraw() public onlyOwner {
        //require(msg.sender == owner, "Sender is not owner!"); //controllo se chi ha chiamato la funzione è il proprietario del contratto
        //pulisco la mappa
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmount[funder] = 0;
        }

        funders = new address[](0); //reset array

        (
            bool callSuccess, /*byte memory dataReturned(è un array)*/

        ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Send(call) failed!"); //possibile revert della transizion
    }

    /*
        Modifier: creo un nuovo modificatore come ad esempio payable o view
    */
    modifier onlyOwner() {
        //avviene prima il codice del modificatore, dipende dalla posizione dell'_
        //require(msg.sender == owner, "Sender is not owner!");
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _; //rappresenta il resto della funzione in cui è applicato il modificatore
    }

    //Cosa accade se qualcuno invia ETH al contratto senza la funzione fund()?

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /*
        In questo modo anche se vengono inviati ETH senza usare fund(), i donatori vengono
        comunque inseriti nel registro.
    */
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    //restituisce il valore di ETH in USD
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData(); //ETH in USD
        //In questo momento price = 300000000000 = 3 * 10^8
        //gli altri valori con cui stiamo lavorando(come msg.value) sono nell'ordine 10^16

        return uint256(price * 1e10); //cosi portiamo il valore nel giusto ordine di grandezza
    }

    //restituisce la versione del contratto
    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    //converte l'importo di ETH in USD
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPriceInUSD = getPrice(priceFeed);

        return (ethAmount * ethPriceInUSD) / 1e18;
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