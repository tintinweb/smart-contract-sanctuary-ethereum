/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

pragma solidity ^0.5.0;

contract Roulette {
    // Définition des constantes
uint256 constant private RED_PROBABILITY = 36;
uint256 constant private BLACK_PROBABILITY = 36;
uint256 constant private GREEN_PROBABILITY = 2;
uint256 constant private MIN_BET = 0.04 ether;
uint256 constant private MAX_BET = 80 ether;

// Ajout de la déclaration pour la variable FEE_RATE
uint256 constant private FEE_RATE = 5;

// Définition des variables
address public owner;
address payable public treasurer;
uint256 public totalBet;
uint256 public totalWin;

    // Définition du constructeur
    constructor() public {
        owner = msg.sender;
        treasurer = msg.sender;
    }

    // Définition de la fonction play()
    function play(uint256 color) public payable {
        // Vérification que la mise est valide
        require(msg.value >= MIN_BET && msg.value <= MAX_BET, "Invalid bet amount");

        // Calcul des probabilités
        uint256 probability = 0;
        if (color == 1) probability = RED_PROBABILITY;
        else if (color == 2) probability = BLACK_PROBABILITY;
        else if (color == 3) probability = GREEN_PROBABILITY;
        else revert("Invalid color");

        // Tirage au sort d'une couleur
        uint256 winningNumber = random(1, 38);
        uint256 winningColor;
        if (winningNumber <= 18) winningColor = 1; // Rouge
        else if (winningNumber <= 36) winningColor = 2; // Noir
        else winningColor = 3; // Vert

        // Calcul des gains
        uint256 winnings;
        if (color == winningColor) {
            if (winningColor == 3) winnings = msg.value * 5; // gain de 500% si la couleur est verte
            else winnings = msg.value; // gain de 100% si la couleur est rouge ou noir
        } else {
            winnings = 0; // perte
        }

        // Calcul des frais
        uint256 fees = msg.value * FEE_RATE / 100;

        // Envoi des fonds au joueur
        msg.sender.transfer(msg.value + winnings - fees);

        // Mise à jour des compteurs
        totalBet += msg.value;
        totalWin += winnings;

        // Envoi des frais au créateur du contrat
        msg.sender.transfer(fees);
}

// Définition de la fonction random()
function random(uint256 min, uint256 max) private view returns (uint256) {
    return min + uint256(keccak256(abi.encodePacked(now, msg.sender, totalBet))) % (max - min + 1);
}
}