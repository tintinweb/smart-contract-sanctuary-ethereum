/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;
pragma abicoder v2;

// Florian GUILLOT
// Aurélien PAYET
// Donatien BERTAUD
// IMT Atlantique - UE BlockChain

contract AuctionContract{
    mapping (address => uint) public ticketsBalance; //Nombre de ticket possédé par l'adresse
    mapping (address => uint) public bid; //Sa mise
    mapping (address => uint) public increase; //Si il a déjà augmenter le prix
    address[] public bidders; //Adresse des parieurs
    address public owner = msg.sender; //Adresse du propriétaire
    address public author = msg.sender; //Adresse du créateur
    uint public soldTickets = 0; //Le nombre de ticket vendu depuis le début de l'action
    uint auction = 0; //If 0, no auction. If 1, auction open.
    uint price = 10; //Prix du contract
    string public url = "https://external-preview.redd.it/jbbjmM3zYXAtvURCmi_2cR4aTT7beImzIg4lZ7uXUHQ.jpg?width=640&crop=smart&auto=webp&s=4d7cafb617d72752ee6a3e3b54fee8a81d6c0dc6"; //Notre magnifique NFT
    
    function getBalance() external view returns(uint){ //Retourne la balance de l'adresse
        return address(this).balance;
    }

    function getTicketBalance() external view returns(uint){ //Retourne le nombre de ticket de l'adresse
        return ticketsBalance[msg.sender];
    }

    function getOwner() external view returns(address){ //Retourne l'adresse du proprio
        return owner;
    }

    function getMaximalBidder() public view returns(address){ //Idem que la fonction en haut, mais retourne l'adresse de celui qui a misé le plus
        uint length= bidders.length; //Nombre de parieur
        uint maxBid = 0; //Pari max
        address maxBidder; //Adresse du bidder max
        for (uint i=0; i<length; i++){ //Pour chaque bidder
            if (bid[bidders[i]]>maxBid)  { //Si sa mise est supérieur à la mise max
                maxBid = bid[bidders[i]]; //On change la mise max
                maxBidder = bidders[i]; //On stock l'adresse du parieur
            }
        }
        return maxBidder;
    }

    function getMaximalBid() public view returns(uint){ //Retourne le prix proposé le plus haut
        return bid[getMaximalBidder()]; 
    }

    function getMinimalPrice() external view returns(uint){ //Retourne le prix minimum du contract
        return price;
    }

    function showBidders() external view returns(address[] memory){ //Donne la liste des parieurs
        return bidders;
    }

    function getPrice() external view returns(uint){ //Retourne le prix min du contract
        return price;
    }
    
    function buy(uint nbTickets) external payable{ //Acheter des tickets
        require(msg.value == nbTickets * (3 gwei)); //Le nombre demandé doit être proportionnel au gwei donné
        ticketsBalance[msg.sender]+= nbTickets; //On lui rajoute ses tickets
        soldTickets=soldTickets + nbTickets; //On augmente la variable du nombre de ticket vendu depuis la création du contract
    }
    
    function sell(uint nbTickets) external{ //Vendre ses tickets
        require(nbTickets<= ticketsBalance[msg.sender]); //Les tickets qu'il vent doivent être en sa possession
        ticketsBalance[msg.sender]-= nbTickets; //On les lui retire
        payable(msg.sender).transfer(nbTickets*(3 gwei)); //On lui redonne en gwei
        soldTickets=soldTickets - nbTickets;
    }

    function newBid(uint nbTickets) external { //Attention nouveau parieur ! Permet de parier ses tickets dans l'enchère
        require(nbTickets<= ticketsBalance[msg.sender]); //Les tickets pariés doivent être en la possession du parieur
        ticketsBalance[msg.sender]-= nbTickets; //On les lui retire
        bid[msg.sender]=nbTickets; //On les enregistres
        if (!member(msg.sender, bidders)) {
            bidders.push(msg.sender); //On enregistre notre parieur dans la liste des parieurs (logique)
        }
        if(auction == 0){ //Open an auction
            auction = 1;
        }
    }

    function closeAuction() external{ //On ferme la vente
        uint maxBid = getMaximalBid(); //On récupère la mise max

        require(maxBid >= price); //Si c'est supérieur au prix demandé

        auction = 0; //Fermeture de la vente
        price = maxBid; //Le prix est changer
        ticketsBalance[owner] += maxBid; //L'ancien proprio se vois gagner les tickets de la vente
        owner = getMaximalBidder(); //Nouveau proprio
        bid[owner] = 0; //Et le nouveau perd sa mise dû a la vente
        ticketsBalance[author]+= 10; //L'auteur gagne 10 tickets à chaque vente

        uint length= bidders.length;
        uint ubid;
        for (uint i=0; i<length; i++){
            ubid = bid[bidders[i]]; //On enregistre la mise du parieur
            bid[bidders[i]] = 0; //On la met à 0
            ticketsBalance[bidders[i]] += ubid; //on lui redonne ses tickets
        }
    }

    function increaseMinimalPrice() external { //Le prorpio peux augmenter le prix du contract, une seul fois (par proprio)
        require((owner == msg.sender) && (increase[msg.sender] == 0));
        increase[msg.sender] = 1;
        price += 10;
    }
    
    function giveForFree(address a) external{ //Le proprio peut donner se contract
        require(owner == msg.sender); //On vérifie bien que c'est le proprio qui le donne
        owner = a; //On change de proprio, j'ajouterai que c'est une faille, car techniquement on peux se créer autant d'adresse que l'on veux. De cette manière on peux augmenter le prix du contract à l'infini (avec increaseMinimalPrice).
    }

    function member(address s, address[] memory tab) pure private returns(bool){
    uint length= tab.length;
    for (uint i=0;i<length;i++){
        if (tab[i]==s) return true;
    }
    return false;
    }

    function check() external view returns(bool,bool){
        return( (soldTickets*(3 gwei) <= this.getBalance()), (soldTickets*(3 gwei) >= this.getBalance()));
    }
}