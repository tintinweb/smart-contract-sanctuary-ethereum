//SPDX-License-Identifier: MIT
//pragma first
pragma solidity ^0.8.8;
//import then
import "./PriceConverter.sol";
//error code then
error FundMe__notOwner(); //nomduContract__error();

//interfaces, Libraries, contract then...
//NatSpec will help us to create a documentation -> https://docs.soliditylang.org/en/v0.8.15/style-guide.html#natspec
/** @title A contract for crowdfunding
 *  @author Patrick Collins
 *  @notice This contract is to demo a sample funding contract
 *  @dev This implements price feeds as our library
 */
contract FundMe{
    //on va déclarer que l'ont veut utiliser les fonctions de la librarie PriceConverter
    //sur les uint256
    //TYPE DECLARATION
    using PriceConverter for uint256;

    //STATE DECLARATION
    address[] public funders;
    mapping(address => uint256) public adresseToAmountWei;
    //quand la porté n'est déclaré pour une variable la porté est en private..
    //on multiplie par 1e18 pour que le prix de l'eth et AMOUNT_IN_USD est
    //le même nombre de decimal pour pouvoir etre comparable
    //ASRUCE : puisque AMOUNT_IN_USD is constant est ne va pas pouvoir être modifier
    //on peut lui mettre la propriétéé constant.. cela permet de réduire les gas lorsque l'ont va
    //vouloir voir sa valeur avec le getter.. convention d'écriture ->en majuscule et unedrscore
    uint256 public constant AMOUNT_IN_USD = 50 * 1e18;

    //Puisque  i_owner est constant et ne va pouvoir être modifier on veut qu'il soit constant aussi
    //(comme AMOUNT_IN_USD) seulement msg.sender est déclaré dans le constructor donc le mettre constant  ne lui
    //permmettrai pas d'être égale à msg.sender --> donc on utilise immutable.. (comme STATIC en C).
    //on économise des gas comme ca si on veut appeler le getter tout comme AMOUNT_IN_USD
    address public immutable i_owner;
    AggregatorV3Interface immutable priceFeed;

    modifier onlyOwner(){
        //require(i_owner == msg.sender, "msg.sender is not the i_owner of this contract !");
        //we can use revert in the new version of the solidity compilatorr in order to do a require but
        //it's requiering less fee
        if(i_owner != msg.sender){ revert FundMe__notOwner();}
        _;
    }


    //constructor
    constructor(address priceFeedAdress){
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAdress);
    }

    //imaginons que quelqu'un envoie des wei à ce contrat sans utiliser fund()
    //l'argent va être stocké dans le contrat mais la personne ne sera pas enrengistrer..
    //on va utiliser les fonctions receive() et fallback()
    //si quelqu'un envoie de l'argent au contrat sans data receive() va être appelé
    //sinon c'est fallback()
    //voir graph en bas de page
    //ces fonctions doivent être external et forcement...payable
    receive() external payable{
        fund();
    }

    fallback() external payable{
        fund();
    }


    /**
    * @notice This function funds this contract
    * @dev This implements price feeds as our library
    */
    function fund() public payable {
        //reverting
        //getConversionRate(msg.value); <-- ancienne manière lorsque getConversionRate(uint 256) était une fonction de FundMe
        require(msg.value.getConversionRate(priceFeed) > AMOUNT_IN_USD, "did not send the requiere amount of USD !");
        //requiere va faire en sorte de rendre le gaz qui reste à celui qui n'apas envoyé assez de d'ETH
        //(du gaz a pu etre utilisé en amount du requiere eet ne sera pas rendu)
        //mais aussi annulez tout ce qui s'est passé dans la fonction ex : chamgement de variable ect ...
        funders.push(msg.sender);
        adresseToAmountWei[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for(uint256 founderIndex = 0 ; founderIndex < funders.length ; founderIndex++)
        {
            adresseToAmountWei[funders[founderIndex]] = 0;
        }
        //resting array funders
        funders = new address[](0);

        //il eciste 3 methodes pour envoyer des ETH d'un contrat a une adresse
        //il faut penser à caster l'adresse msg.sender en payable pour les 3 méthodes
        //transfer : rend directement le gas et renvoi une exeption en cas d'erreur
        payable(msg.sender).transfer(address(this).balance);

        //send : il faut en plus de send() un requiere si on veut renvoyer lle gas restant .. (et renvoi un bool)
        //plutot qu'une exeption
        bool sendSucess = payable(msg.sender).send(address(this).balance);
        require(sendSucess, "send Failed ! ");

        //call : meilleur manière a voir sur la doc pk, renvoi un bool et un byte contenant certains data
        (bool callSucess,) = payable(msg.sender).call{value : address(this).balance}("");
        require(callSucess, "call Failed ! ");
    }
}

// Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()

//order of the function
    //constructor
    //receive function (if exists)
    //fallback function (if exists)
    //external
    //public
    //internal
    //private

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//on import l'ABI (la declaration des fonction de AggregatorV3) sinon les fonction comme latestRoundData()
//ne seront pas comprise par le compilo ...
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//toutes les fonctions d'une librarie doivent être en mode : internal
//les libraries ne doivent pas contenir d'instance de quoi que ce soit (ni même des uint...)...
library PriceConverter {

    function gePrice(AggregatorV3Interface priceFeed) internal view returns(int256)
    {
        //les fonctions dans l'interface seront implémenté grâce à l'adresse 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        //qui est l'adresse du SM present dans le testNET RINKEBY
        (,int256 ETHPrice,,,) = priceFeed.latestRoundData();

        //je dois multiplier par 1e10 car ETHPrice est précis a 8 decimal seulement
        //pour le mettre a niveau avec les unité de wei pour la suite je dois lui ajouter 10 zéro
        //voir fonction decimals dans l'interface AggregatorV3Interface.sol
        return ETHPrice * 1e10;
    }

    function getConversionRate(uint256 amountETH, AggregatorV3Interface priceFeed) internal view returns(uint256)
    {
        int256 ETHPrice = gePrice(priceFeed);
        //ensolidity on ne travail pas avec des floatant pour ne pas perdre en precision c'est pourquoi on
        //garde que l'ont travail pricipalement avec des WEI dans les code...
        //ici on divise pas 1e18 pour passer amountETH de wei en eth
        //ex 1_000000000000000000 wei --> 1 eth
        return (uint256(ETHPrice) * amountETH) / 1e18;
    }
}

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