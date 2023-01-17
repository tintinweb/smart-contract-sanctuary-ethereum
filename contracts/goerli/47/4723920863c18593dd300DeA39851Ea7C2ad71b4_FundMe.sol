// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

//On devra d'abord importer le package fourni par Chainlink
import "AggregatorV3Interface.sol";
//On va importer la librairie SafeMath de Chainlink
import "SafeMathChainlink.sol";

//On cree un contrat capable de recevoir de l'argent
contract FundMe {
    //Pour utiliser la librairie SafeMath on utilise le mot cle "using"
    using SafeMathChainlink for uint256;
    //On fait un mapping de l'adresse qui a envoye les fonds
    mapping(address => uint256) public addressToAmountFunded;
    //On intancie un array qui stocke l'addresse de ceux qui ont envoyes des fonds
    address[] public funders;

    //On instancie l'addresse du proprietaire
    address public owner;
    //On cree un "constructor" pour defenir le proprietaire du contrat
    constructor() public {
        owner = msg.sender;
    }

    //On instancie la fonction de paiement avec le mot cle "payable"
    function fund() public payable {
        //On peut parametrer le prix de notre fonction fund sur n'importe quel prix que l'on souhaite en dollar (50$) 
        //Maintenant on mettre un un seuil de reception de fonds en dollar (ici le seuil minimum est de 50$)
        uint256 minimumUSD = 50 * 10 ** 18; /*mais en Wei*/
        //La fonction "require" va verifier si le montant recu est superieur a 50$ en Wei
        require(getConversionRate(msg.value) >= minimumUSD, "Tu as besoin d'envoyer plus d'Etherum !");
        addressToAmountFunded[msg.sender] += msg.value;
        //On met l'addresse de ceux qui ont envoyes les fonds dans l'array
        funders.push(msg.sender);
        //Quel est le taux de conversion entre ETH et USD et comment l'avoir dans le smart contrat ?

    }

    //On cree une fonction qui recupere la version a partir du contrat externe
    function getVersion() public view returns (uint256){
        AggregatorV3Interface /*le type de l'interface*/ fluxPrix = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e/*l'addresse ou l'on trouve les donnees du prix*/);
        return fluxPrix.version() /*on renvoi la version de l'interface utilise*/;
    }
    //Maintenant on cree une fonction qui recupere et nous renvoie le dernier prix
    function getPrice() public view returns(uint256){
        AggregatorV3Interface fluxPrix = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        //On peut juste garder la variable answer, en mettant rien sur les autres variables de retour pour eviter les erreurs de compilation
        (,int256 answer,,,) = fluxPrix.latestRoundData();
        return uint256(answer * 10000000000/*pour obtenir le prix en Wei*/); /*sera le prix qu'on va convertir par un type casting en unit256*/
    }

    //On cree une fonction qui est en mesure de convertir la somme recu en Etherum en Dollar
    function getConversionRate(uint256 ethAmount) public view returns (uint256) {
        uint256 prixEth = getPrice();
        uint256 ethAmountInUsd = (prixEth * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
        // le resultat donne = 1279603316090 et en le convertissant en dollar on a : 0,000001279603316090 le prix d'un Gwei en Dollar
    }

    //Les "modifiers"
    modifier onlyOwner {
        //On souhaite que seul le proprietaire du contrat puisse retirer les fonds
        require(msg.sender == owner);
        _;
    }
    //On instancie la fonction de retrait avec mot cle payable
    function withdraw() public onlyOwner payable {
        //la fonction native "tranfer" permet d'envoyer des ethers d'une adresse a un autre
        msg.sender.transfer(address(this/*represente le contrat dans lequel nous sommes*/).balance/*pour envoyer tous les fonds recus*/);
        //un fois que les fonds sont retires on va remettre l'array des envoyeurs de fonds a zero
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //On va mettre l'adresse des envoyeurs de fonds dans un nouveau array
        funders = new address[](0);
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