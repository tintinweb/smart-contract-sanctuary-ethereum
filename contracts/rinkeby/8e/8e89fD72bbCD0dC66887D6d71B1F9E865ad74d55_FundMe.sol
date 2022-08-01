//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";
error NotOwner(); //déclarer l'erreur possible en dehors du contrat

contract FundMe {
    using PriceConverter for uint256; //a approfondir

    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded; //address est la variable dont on va demander l'équivalent

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress){ //fonction appelée dès le déploiement du contrat
        i_owner = msg.sender; //dans ce cas msg.sender = celui qui déploie le contrat
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        //require(msg.value >= 1e18, "Didn't send enough!"); //recquiert un envoi de+ de 1e18 Wei (1ETH)
        //require(getConversionRate(msg.value) >= minimumUSD, "Didn't send enough!");
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "Didn't send enough!");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
        //Ajout dans l'array de la liste des donateurs et ajout au mapping de leur équivalent en ETH
    }

    function withdraw() public onlyOwner {
        /*starting index, ending index, step amount */
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex = funderIndex + 1){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0); //Identifier funders correspond maintenant à un nouvel array "address[]" de 0 éléments
        

        /*
        //Méthode transfer --- payable(msg.sender) = adresse payable --- revert if failed
        payable(msg.sender).transfer(address(this).balance); //(this) = ce contrat

        //Méthode send --- renvoie un bouléen false mais envoi retire les fonds
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");
        */


        
        //Méthode call --- permet d'appeler des fonctions. Ici pas de fonction ("")
        //retourne 2 variables (donc à déclarer avant) mais dataReturned ne sert pas dans ce cas
        (bool callSuccess, /*bytes memory dataReturned*/) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
        //meilleure méthode à ce jour (pas de gas limit)
    }

    //modifie toutes les fonctions qui auront cette propriété
    modifier onlyOwner {
        /*require(msg.sender == i_owner, "Sender is not i_owner!");*/
        if(msg.sender != i_owner) {
            revert NotOwner();
        }
        _; //correspond au reste du code de la fonction qui possède cette propriété
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; //Importe le contrat à l'adresse GitHub

library PriceConverter {
//Toutes les fonctions doivent êtres internes
//Une librairie ne peut pas envoyer d'ETH, uniquement faire des view

    function getPrice (AggregatorV3Interface priceFeed) internal view returns(uint256) {

        /*AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e); 
        //variable priceFeed dans Aggregator, et trouver le contrat à tel adresse */
        
        (,int256 price,,,) = priceFeed.latestRoundData(); //La fonction renvoi plusieurs data (d'où les virgules)
        return uint256(price * 1e10); //Même nombre de décimal nécessaire par rapport à msg.value qui est en Wei
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethAmount * ethPrice) / 1e18; //Division pour avoir un résultat lisible
        return ethAmountInUsd;
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