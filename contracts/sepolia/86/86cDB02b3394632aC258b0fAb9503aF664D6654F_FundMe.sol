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

pragma solidity ^0.8.8;

// Obiettivi:
// Ottenere fondi dagli utenti
// Prelevare fondi
// Impostare una soglia minima di finanziamento (sia in termini di criptovaluta che in termini di valuta tradizionale)

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD = 50 * 1e18;

    // Creiamo una struttura dati di tipo array che servirà per tenere traccia delle persona che hanno inviato soldi al contratto
    address[] public funders;

    // Creiamo un mapping che mette in relazione l'indirizzo dei donatori con la somma donata
    mapping(address => uint256) public addressToAmountFunded;

    // Proprietario del contratto (colui che effettua il deploy)
    address public immutable i_owner;

    // Codifichiamo il price feed coma variabile globale: verrà inizializzata nel costruttore all'atto del deploy in base alla specifica blockchain che utilizziamo
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // Funzione per inviare soldi al contratto. Tutti devono essere in grado di inviare soldi al
    // contratto in questione e dunque di richiamare tale funzione
    function fund() public payable {
        // require(getConversionRate(msg.value) >= MINIMUM_USD, "Didn't send enough"); //1e18 = 1*10^18 --> valore in Wei di 1 ETH

        // Facendo ricorso alla libreria PriceConverter possiamo utilizzare la seguente sintassi per richiamare la funzione getConversionRate
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, //Come secondo parametro della funzione getConversionRate passiamo il priceFeed che abbiamo inizializzato nel costruttore
            "Didn't send enough"
        );
        // Nella riga di sopra non passiamo alcuna variabile alla getConversionRate nonostante nella sua definizione nella libreria PriceCOnverter
        // la funzione prende un uint256. Questo perché msg.value è considerato dietro le quinte come il primo parametro della funzione di libreria.
        // Se la funzione prendesse anche un secondo parametro allora questo, all'atto della chiamata, lo andremmo a inserire tra le parentesi

        // Ogni qual volta qualcuno invia monete al contratto lo andiamo a memorizzare nell'array funders
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    /* TUTTO IL CODICE SEGUENTE COMMENTATO E' STATO SPOSTATO NELLA LIBRERIA PRICECONVERTER
    // Per esprimere la quantità minima di soldi da inviare in termini di ETH abbiamo bisogno di una funzione
    // che ci permette di ottenere il tasso di conversione

    function getPrice() public view returns (uint256){
        // Qui andremo a richiamare un contratto esterno che offre le funzionalità Price Data Feeds di Chainlink
        // Per interagire con tale contratto avremo bisogno di due elementi: l'ABI e l'address.
        // L'address lo andiamo a prendere dalla sezione Price Feed Addresses della documentazione Chainlink relativa ai Data Feeds.
        // Scorriamo fino a trovare la sezione relativa alla nostra testenet (Sepolia) e copiamo l'indirizzo associato alla 
        // conversione che ci interessa, in questo caso ETH/USD: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        // Per ottenere l'ABI del contratto possiamo sfruttare il concetto di interfaccia, la quale presenta diverse dichiarazioni di funzioni
        // ma nessuna di esse implementa la logica della funzione (non viene specificato cosa le funzioni fanno in realtà). 
        // Se compiliamo un'interfaccia di fatto otteremo l'ABI di un contratto perché definisce tutte le modalità attraverso cui possiamo 
        // interagire con il contratto.
        // In questo esempio possiamo andare a prendere l'interfaccia relativa all'AggregatorV3 (https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol)
        // ed incollarla prima di questo contratto (dopo vedremo anche un'alternativa ad incollare).
        // Una volta che abbiamo l'interfaccia di AggregatorV3 possiamo usarla per fare chiamate alle API come nella funzione getVersion di seguito
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (,int256 price,,,) = priceFeed.latestRoundData(); //Otteniamo il valore di ETH in termini di USD
        // Questo prezzo avrà 8 cifre decimali. Dobbiamo portarlo a 18 cifre decimali quindi moltiplicheremo per 1e10
        return uint256(price * 1e10); //casting a uint256 
        }

    function getVersion() public view returns (uint256) {
        // Creiamo una variabile di tipo AggregatorV3Interface a partire dall'address del Price Feed
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        //Ritorniamo il risultato della funzione version(), cioè la versione del price feed.
        return priceFeed.version();
    }

    // Funzione per convertire Ethereum in USD, verrà richiamata all'interno della funzione fund()
    function getConversionRate(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice(); //Richiamiamo la funzione getPrice definita sopra per ottenere il valore di 1 ETH
        uint256 ethAmountInUSD = (ethAmount * ethPrice) / 1e18; //Dividiamo per 1e18 altrimenti otterremo un numero con 36 cifre decimali in quanto sia ethPrice che ethAmount hanno 18 cifre decimali
        return ethAmountInUSD;
    }
*/

    // Una volta che sono stati inviati fondi al contratto, dobbiamo fare in modo che questi possano essere prelevati.
    // Creiamo quindi una funzione di prelievo

    // Modifier utilizzato per la funzione withdraw
    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not i_owner!");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    function withdraw() public onlyOwner {
        // Innanzitutto, quando viene effettuato il prelievo, vogliamo resettare l'array dei funders e il mapping riportando a 0 tutte le somme versate
        // Per riportare a 0 tutte le somme versate ndai diversi indirizzi utilizziamo un ciclo for che preleva ciascun indirizzo dall'array funders e poi va a settare il valore corrispondente nel mapping a 0
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++ /* aumentà di 1 e poi fa il check sulla condizione */
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // Ora resettiamo l'array funders:
        funders = new address[](0); // L'array funders ora avrà 0 elementi al suo interno

        // Ora dobbiamo prelevare effettivamente i fondi da questo contratto: dobbiamo inviare i fondi a
        // chi richiama tale funzione.
        /*
        // Modalità 1 utilizzando transfer()
        payable(msg.sender).transfer(address(this).balance);
        // msg.sender è di tipo address
        // payable(msg.sender) è di tipo payable address (è necessario questo cast a payable)
        // infatti per inviare criptomoneta si deve lavorare solamente con payable address

        // Modalità 2, funzione send()
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");
        */

        // Modalità 3, funzione call()
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed!");
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // Togliamo le seguenti funzioni dal contratto FundMe e le incolliamo qui.
    // Anzichè dichiararle come public, tali funzioni saranno "internal" e ciò ci permetterà di richiamarle direttamente su
    // un oggetto di tipo uint256, ad esempio msg.value.getConversionRate()

    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        //getPrice prende come parametro il priceFeed specifico per la blockchain utilizzata, permettendoci di togliere l'indirizzo dalle righe successive e rendendo il tutto più modulare
        /* AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        ); */
        (, int256 price, , , ) = priceFeed.latestRoundData(); //Otteniamo il valore di ETH in termini di USD
        // Questo prezzo avrà 8 cifre decimali. Dobbiamo portarlo a 18 cifre decimali quindi moltiplicheremo per 1e10
        return uint256(price * 1e10); //casting a uint256
    }

    function getVersion(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // Creiamo una variabile di tipo AggregatorV3Interface a partire dall'address del Price Feed (non serve più perché parametrizzato)
        /* AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        ); */
        //Ritorniamo il risultato della funzione version(), cioè la versione del price feed.
        return priceFeed.version();
    }

    // Funzione per convertire Ethereum in USD, verrà richiamata all'interno della funzione fund()
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed // Aggiunto un secondo parametro priceFeed che dipenderà dalla specifica blockchain utilizzata
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed); //Richiamiamo la funzione getPrice definita sopra per ottenere il valore di 1 ETH, passiamo come parametro il priceFeed
        uint256 ethAmountInUSD = (ethAmount * ethPrice) / 1e18; //Dividiamo per 1e18 altrimenti otterremo un numero con 36 cifre decimali in quanto sia ethPrice che ethAmount hanno 18 cifre decimali
        return ethAmountInUSD;
    }
}