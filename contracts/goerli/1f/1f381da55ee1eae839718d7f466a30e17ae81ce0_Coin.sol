/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

pragma solidity >0.4.99 <0.6.0;
// Déclaration de la version du compilateur supérier à 0.4.99 jusqu'à 0.6.0 sans le compter dedans

// Déclaration d'un contrat qui aura pour nom Coin
contract Coin{

    //Déclaration d'une variable d'état publique de type address sur 160 bits qui sera
    //aussi l'adresse du créateur du contrat
    address public minter;

    //Créé une variable d'état publique pour voir la balance des comptes
    mapping (address => uint) public balances;

    //Création d'un event pour échanger le jeton sur le contrat
    event Sent (address from, address to, uint amount);

    //Fonction spéciale éxucutable à la création du contrat et stocke l'adresse
    //du créateur du contrat de façon permanente
    constructor() public{

        //Variable spéciale qui permet d'accèder à la blockchain
        minter = msg.sender;
    }

    //Fonction mint pouvant être appellée par les utilisateurs mais sera en echéc car seul
    //créteur peut mint de nouveaux jetons
    function mint (address receiver, uint amount) public{

        //Seul le créateur peut mint de nouveaux jetons avec la variable require
        require (msg.sender == minter);

        //La limite d'offre du jeton
        require (amount < 1000000000000000);
        balances [receiver] += amount;
    }

    //Fonction send pour envoyer des jetons entre utilisateurs
    function send (address receiver, uint amount) public{

        //Message d'erreur seulement affiché si vous n'avez pas les jetons
        require (amount <= balances [msg.sender], "Insufficient balances");

        //Montant de l'envoi
        balances [msg.sender] -= amount;

        //montant du reçu
        balances [receiver] += amount;

        //Transaction vu sur la blockchain
        emit Sent (msg.sender, receiver, amount);
    }
}