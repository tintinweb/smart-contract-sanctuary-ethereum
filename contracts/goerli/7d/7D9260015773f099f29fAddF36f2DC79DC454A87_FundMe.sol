// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";

// Questo contatto deve accettare un qualche tipo di pagamento
contract FundMe
{
    // Aiuta a non andare in overflow con le operazioni matematiche
    // I controlli sono fatti automaticamente
    using SafeMathChainlink for uint256;

    // Un mapping che dato un indirizzo ci restituisce il valore pagato
    mapping(address => uint256) public addressToAmountFunded;

    // Array che contiene solo gli indirizzi dei funders. Ci servirÃ  per accedere ai valori del mapping
    address[] public funders;

    // indirizzo propeitario del contratto
    address public owner;

    // priceFeed globale
    AggregatorV3Interface public priceFeed;
    
    // Creiamo un costruttore, ovvero una funzione che viene chiamata non appena viene deployed
    // un contratto, questo ci permette tra le tante cose di settare l'owner
    constructor(address _priceFeed) public 
    {
        // chiunque crei e inserisca nella blockchain questo smart contract Ã¨ il msg.sender (SOLO NEL CONSTRUCTOR)
        // Settiamo l'owner a noi stessi
        owner = msg.sender;

        // Dobbiamo inizializzare AggregatorV3Interface con lo smartContract con cui vogliamo comunicare
        // ovvero quello che ci fornisce le informazioni di cambio tra ETH e USD. Per fare questo possiamo
        // andare su docs.chain.link e cercare l'indirizzo nella blockchain (che dipende dalla rete in cui siamo) 
        // di questo smartcontract. In questo caso proveremo sulla Goerli Testnet
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    // Una funzione che accetta un pagamento in ETH puÃ²/deve avere la keyword payable
    // Queste funzioni avranno un "value" associato che rappresenta una quantitÃ  di ETH
    // da inviare
    function fund() public payable
    {
        // Noi perÃ² vogliamo (arbitrariamente) che la donazione abbia un valore minimo in USD
        // (quindi non in ETH), per fare questo avremo bisogno di un ORACOLO che ci dica il 
        // tasso di conversione corrente
        uint256 minimumUSD = 50 * (10 ** 18); // Vogliamo che tutti i nostri numeri abbiamo 18 decimal places cosÃ¬ da matchare wei e ETHER
        
        // Se non viene verificato il require il pagamento viene reverted in automatico e si esce dalla funzione
        // La stringa "You need to spend more ETH" Ã¨ l'error message
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH");

        // msg.sender Ã¨ l'indirizzo del pagante (che puÃ² essere un wallet o un altro smart contract) e msg.value
        // il valore inviato
        addressToAmountFunded[msg.sender] += msg.value;

        // Salviamo in un array tutti i funders cosicchÃ¨ quando si preleva i loro bilanci saranno a 0
        // Ci serve salvarli in un array perchÃ¨ non possiamo loopare su un mapping
        funders.push(msg.sender);
    }

    // Un modificatore Ã¨ una funzione che viene eseguita prima (o dopo, in base a dove mettiamo _;) una
    // funzione modificata con il nome del modificatore. withdraw Ã¨ modificata con onlyOwner, infatti verrÃ 
    // eseguita dopo onlyOwner perchÃ¨ abbiamo inserito _; dopo il corpo della "funzione" onlyOwner
    modifier onlyOwner
    {
        // Chiunque chiami la funzione di withdraw Ã¨ il msg.sender
        // Noi vogliamo che solo il proprietario del contratto possa prelevare i soldi:
        // require msg.sender == owner
        require(msg.sender == owner, "You have to be the owner to withdraw the money");
        _;
    }

    // Per adesso il contratto possiamo solo pagarlo, ma i soldi rimangono lÃ¬ sul contratto
    // e non possiamo farci niente, dobbiamo creare una funzione di withdraw
    function withdraw() payable onlyOwner public
    {
        // Trasferiamo i soldi al msg.sender (che deve essere necessariamente l'owner per il require)
        msg.sender.transfer(address(this).balance);

        // Vogliamo resettare tutti i bilanci di chi ha donato (credo sia solo un modo per spiegare il for loop in solidity)
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++)
        {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // Resettiamo il funders array, ovvero lo associamo ad un nuovo array vuoto
        funders = new address[](0);
    }

    function getVersion() public view returns(uint256)
    {        
        return priceFeed.version();
    }

    // Chainlink Ã¨ una rete di oracoli decentralizzati che, tra le tante informazioni che fornisce
    // alla blockchain, la piÃ¹ importante (e quella per cui Ã¨ usato maggiormente) sono i tassi di conversione e vari price feeds 
    function getPrice() public view returns(uint256)
    {
        // Abbiamo definito una tupla, per le variabili che non ci interessano usiamo le virgole al loro posto
        (,int256 answer,,,) = priceFeed.latestRoundData();
        // converto answer in uint. answer ha 8 decimal digits, noi vogliamo che ne abbia 18 cosÃ¬
        // da matchare i wei rispetto agli ETHER, moltiplichiamo quindi per 10^10
        return uint256(answer * (10**10));
    }

    // Restituisce il conversion rate tra eth e dollaro
    // vuole l'ethAmount in wei
    function getConversionRate(uint256 ethAmount) public view returns(uint256)
    {
        uint256 ethPrice = getPrice();
        // Abbiamo che ethAmount e ethPrice hanno 10**18 decimal places ciascuno. ethAmountInUsd deve avere 10^18 decimal
        // places, quindi eseguiamo 10^18*10^18/10^18 = 10^18
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / (10**18);
        return ethAmountInUsd;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}