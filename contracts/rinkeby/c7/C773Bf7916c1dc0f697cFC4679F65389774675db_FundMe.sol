/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: fundMe.sol

contract FundMe {
    // Tuple lista di oggetti con tipi differenti
    // (uint80 roundId,
    // int256 answer,
    // uint256 startedAt,
    // uint256 updatedAt,
    // uint80 answeredInRound) = priceFeed.latestRoundData();
    // se non utilizzo alcune di queste varibili posso sostituirle con uno space con la virgola alla fine per mantenere la stessa struttura definita dal metodo
    // guarda il metodo getPrice() per reference

    // msg.value amount di quanto viene mandato, per impostare quanto sto mandando a sinistra dove c'è VALUE sotto GAS LIMIT devo impostare un'amount
    // msg.sender indirizzo di chi ha invocato la funzione in questo caso

    //mappatura di un address a un amount che è stato fundato da quell'address
    mapping(address => uint256) public addressToAmountFunded;
    // address dell owner
    address[] public funders;
    address public owner;

    //metodo costruttore che va ad eseguire delle line prima di tutto il resto
    // costruttore è come una function che viene chiamata subito appena viene deployato il contratto
    constructor() public {
        // associo la owner address a me che ho deployato il contratto
        // msg.sender sono io che sto interagendo il contratto mentre premo i bottoni
        owner = msg.sender;
    }

    // payable indica che questa funzione permette di inviare dei fondi
    function fund() public payable {
        // creazione di un trashold Minimo di $50
        // la "**" prima di "18" indica l'elevamento a potenza dato che lavoriamo con l'unita wei
        // 10 ** 18 -> 1000000000000000000 wei -> 1000000000 gwei -> 1 eth
        uint256 minUSD = 50 * 10**18;
        // require è come una if ma di meglio praticità e permette di terminare l'esecuzione di un contratto se la condizione inserita non è soddisfatta ed esegue ciò che è chiamato
        // revert, ridando i soldi al proprietario ma senza la fees pagate
        require(
            getConversionRate(msg.value) >= minUSD,
            "You need at least 50$"
        );
        // require(condizione, "messaggio di revert");
        // questa mappatura permette di vedere inserendo un'address quanto ha inviato di wei
        // vedila come una storicizzazione
        addressToAmountFunded[msg.sender] += msg.value;
        // aggiunta delle address di chi ha inviato denaro in un'array di tipo address
        funders.push(msg.sender);
    }

    // recupero versione dell'aggregator di ChainLink
    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        // istanzio Aggregator importato da chainlink per verificare la priceFeed
        // per recuperare il priceFeed nella firma devo passare il contratto del proxy per la pair ETH / USD
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        // Definition of a Tuple => utilizzata quando una funzione ritorna più di un dato, è possibile definire tra () i dati che vengono restituiti con "tipo_variabile" "nome_variabile".
        // se non mi servono tutte le variabile che vado a definire e per evitare warning nell'IDE posso decidere di rimuovere la definizione della variabile che viene restituita e lasciare
        // uno spazio vuoto così da manentere coerente la definizione del Tuple con il numero esatto di dati restituiti ma senza istanziare variabili che non userò nella funzione.
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // per fare la return di answer di tipo int256 a uint256 devo convertirla con uint256()
        // processo chiamato 'TypeCasting'
        return uint256(answer);
    }

    // 1000000000 wei -> 1 gwei -> 0.00000000001 eth
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        // richiamo la funzione getPrice() che gli restituisce il prezzo
        uint256 ethPrice = getPrice();
        // Ottengo il reale valore in dollari
        // !! è necessaria la divisione finale perchè il prezzo che viene restituito da getPrice è in wei, unità più bassa di ETH !!
        // non esistendo decimali dobbiamo fare questo tipo di cut
        // valore massimo di wei => 100000000000000000
        uint256 ethAmountUSD = (ethPrice * ethAmount) / 100000000000000000;
        return ethAmountUSD;
    }

    //Modificatore
    // modifica il comportamento di una funzione in base a quello che viene definito al suo interno.
    // viene eseguito il suo comportamento prima della funziona a cui viene associato.
    modifier onlyOwner() {
        // verifico che la persona che sta eseguendo questo contratto abbia la stessa address
        require(msg.sender == owner);
        // "_;" significa esegui tutto il codice dopo nella funzione
        _;
    }

    // funzione per recuperare un importo fundato precedentemente ma solo dall'owner imposto con 'onlyOwner'
    function withdraw() public payable onlyOwner {
        // manda un'amount specificato dal contract a chi invoca la funzione
        // address(this) indica l'indirizzo di questo contratto
        // .balance restituisce il valore di quello che è stato inviato a questo contratto
        // require imposta che questa funzione può essere eseguita solamente se l'address di chi la invoca è uguale all'owner, owner viene istanziato immediatamente nel costruttore in testa
        msg.sender.transfer(address(this).balance);

        // reset di mapping e array funders
        // For Loop
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            // recupero adress di ogni singolo funder dall'array di funders
            address funder = funders[funderIndex];
            // dalla mappatura gli dico che all'address impostato gli metto 0
            addressToAmountFunded[funder] = 0;
        }
        // resetto anche l'array di address di chi ha inviato denaro istanziando l'array nuovamente
        funders = new address[](0);
    }
}