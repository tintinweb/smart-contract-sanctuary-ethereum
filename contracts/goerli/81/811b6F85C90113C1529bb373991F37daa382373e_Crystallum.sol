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

//Crystallum contract
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//Imports de la libraire et de l'oracle permettant de récupérer le prix actuel de l'Ether
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

contract Crystallum {
    using PriceConverter for uint256;

    //Prix de la bouteille: 10 centimes
    uint256 public constant PRICE_BOTTLE = 0.1 * 10 ** 18;
    //Adresse du propriétaire du contrat
    address private immutable i_owner;
    //Fonctions permettant de lier un wallet à un montant et un wallet à son nombre de bouteilles
    mapping(address => uint256) private s_accountToBalance;
    mapping(address => uint256) private s_accountToNumberOfBottles;
    //Créer le contrat avec l'oracle de Chainlink
    AggregatorV3Interface private s_priceFeed;

    //Condition pour que seul le propriétaire du contrat peut appeler la fonction
    modifier onlyOwner() {
        require(msg.sender == i_owner, "You are not the owner");
        _;
    }

    //Définit le propriétaire du contrat et l'adresse du contrat Chainlink, tout ca dès le déploiement du contrat Crystallum
    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    fallback() external payable {
        fundContract();
    }

    receive() external payable {
        fundContract();
    }

    //Fonction permettant de définir le nombre de bouteilles placées dans la machine pour un utilisateur
    function setBottles(uint256 _numberOfBottles) public {
        s_accountToNumberOfBottles[payable(msg.sender)] += _numberOfBottles;
    }

    //Fonction permettant de retirer l'Ether en fonction du nombre de bouteilles qu'on a placées dans la machine
    function retrieve() public payable {
        //Vérifie si l'utilisateur a bien placé des bouteilles dans la machine
        require(
            s_accountToNumberOfBottles[msg.sender] > 0,
            "You have no bottles to retrieve"
        );
        //Définit le montant en dollars à récupérer
        uint256 amount = (s_accountToNumberOfBottles[msg.sender] *
            PRICE_BOTTLE);
        //Définit le montant en Ether à récupérer (ne marche pas pour l'instant car le contrat de Chainlink est off)
        amount = PriceConverter.usdToEth(amount /*, s_priceFeed**/);
        //Vérifie que le montant requis est inférieur aux fonds du contrat
        require(
            address(this).balance >= amount,
            "Not enough balance to transfer"
        );
        //Envoie l'Ether à l'utilisateur
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failing to send ether");
        s_accountToBalance[msg.sender] += amount;
        //Remet le compteur de l'utilisateur à zéro
        s_accountToNumberOfBottles[msg.sender] = 0;
    }

    function fundContract() public payable {}

    //Fonction Send qui ne marche pas, à chercher
    // function send(address payable _to) public payable {
    //     require(_to != address(0), "Adresse invalide");

    //     _to.transfer(msg.value);

    //     s_accountToBalance[msg.sender] -= msg.value;
    // }

    //Fonction qui récupère l'adresse du propriétaire
    function getOwner() public view returns (address) {
        return i_owner;
    }

    //Fonction qui récupère le montant du wallet de l'utilisateur en fonction du nombre de bouteilles placées
    function getBalance(address _address) public view returns (uint256) {
        return s_accountToBalance[_address];
    }

    //Fonction qui récupère le nombre de bouteilles placées pour un utilisateur
    function getNumberOfBottles(
        address _address
    ) public view returns (uint256) {
        return s_accountToNumberOfBottles[_address];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}

//Crystallum contract
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    //Fonction qui permet de récupérer le prix de l'Ether (ne marche pas pour l'instant à cause de l'oracle Chainlink)
    function getPrice()
        internal
        view
        returns (
            // AggregatorV3Interface priceFeed
            uint256
        )
    {
        // (, int256 answer, , , ) = priceFeed.latestRoundData();
        // return uint256(answer * 10000000000);
        return 2000;
    }

    function ethToUsd(
        uint256 ethAmount
    )
        internal
        view
        returns (
            // AggregatorV3Interface priceFeed
            uint256
        )
    {
        uint256 ethPrice = getPrice /*priceFeed**/();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 10 ** 18;
        return ethAmountInUsd;
    }

    function usdToEth(
        uint usdAmount
    )
        internal
        view
        returns (
            // AggregatorV3Interface priceFeed
            uint256
        )
    {
        uint256 ethPrice = getPrice /*priceFeed**/();
        uint256 usdAmountInEth = usdAmount / ethPrice;
        return usdAmountInEth;
    }
}