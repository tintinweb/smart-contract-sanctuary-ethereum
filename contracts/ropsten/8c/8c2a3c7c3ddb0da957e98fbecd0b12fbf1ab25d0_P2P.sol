/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

pragma solidity ^0.5.11;

contract P2P {
    address payable client;
    address public administrateur;
    address public adresseNouvelAssure;
    address public assureLese;
    bool montantPrime; 
    bool sinistre;
    bool vote_remboursement;
    int remboursement;
    mapping (address=>uint) prime;
    mapping (address=>bool) vote;
    uint debut;
    uint montantDeLaPrime;
    uint [2] votes; 
    uint resultat; 
    
    
    constructor () public  {
        administrateur=msg.sender;
        debut = block.timestamp;
    }
    
    modifier aDejaVote () {
        require(!vote[msg.sender],"vous avez deja vote");
        _;
    }
    
    modifier demande_accepte ( uint ) {
        require (resultat >7, "le remboursement est accepte");
        _;
    }
    
    modifier demandeRefusee () {
        require (votes[1]>=7,"votre demande a ete refusee");
        _;
    }
    
    modifier impossibleDeRetirer(uint montant) {
      require (prime[msg.sender]>=montant,"il ne peut pas retirer");
        _;
    }
    
    modifier interditAdministrateur () {
        require (administrateur!=msg.sender,"l'administrateur ne peut pas executer cette fonction");
        _;
    }
    
    modifier onlyadministrateur () {
        require (administrateur==msg.sender, "seulement l'administrateur peut definir l'adresse de l'asuré");
        _;
    }
    
     modifier propositionValide (uint laProposition) {
        require (laProposition>=0 && laProposition<3);
        _;
    }
    
    modifier temps_ecoule () {
        require (block.timestamp-debut<=220, "le temps valable de 7 jours pour voter est ecoule");
        _;
    }
    
    modifier temps_ecoule2() {
        require(block.timestamp-debut>=200, "Vous pouvez encore voter");
        _;
    }

    modifier versement_reserve () {
        require (block.timestamp-debut>=230, "Le reste du montant_utilisable peut etre transfere a la reserve chaque annee"); 
        _;
    }
    //l'administrateur défini l'adressse qui va payer la prime correspondant à la fonction definitionPrime
    function adresseSouscription (address uneAdresse) public onlyadministrateur   {
        adresseNouvelAssure=uneAdresse;
    }
    
    //annonce du sinistre afin de faire une demande de remboursement
    function annonce_sinistre () public interditAdministrateur{
        sinistre=true;
        assureLese=msg.sender;
    }
    
    //affiche l'ensemble des primes 
    function cumuldesprimes ()public view returns (uint) {
        return address(this).balance;
    }
    
    //l'administrateur défini la prime qui va être payé par l'assué en question 
    function definitionPrime (uint montant) public onlyadministrateur{
        montantPrime=true; 
        montantDeLaPrime=montant;
    }
    
    function demande_remboursement () public view  returns (bool) {
        return sinistre;
    }
    
        //montant qui va être rendu à l'assuré dans le cas où il y a ecnore de l'argent dans le pot commun 
    function giveback (uint montant_reserve) public view returns (uint) {
        if (montant_reserve>0) {
            return montant_reserve *40/100;
        } else {
            return 0; 
        }
    }    
    
    //montant qui peut être utilise pour dédomager les assurés qui correpsond à 2/3 de l'ensemble des primes 
    function montant_utilisable (uint montant_cumuldesprimes) public view onlyadministrateur returns (uint256){
        return montant_cumuldesprimes*60/100;
    }
    
    //paiement de la prime 
    function primes () public payable interditAdministrateur {
        prime[msg.sender]+=msg.value;
    }
    
    //permet d'affciher la prime qu'à souscrit un assuré spécifique en indiquant l'adresse de l'assuré que l'on veut voir 
    function primedefinie (address assure) public view  onlyadministrateur returns (uint) {
        if (assure==adresseNouvelAssure) {
            return montantDeLaPrime;
        }else {
            return 0;
        }
    }    
    
    //montant allant auprès d'une réassurance dans le cas où le montant_utilisable est insuffisant 
    function reassuance (uint montant_cumuldesprimes) public view onlyadministrateur returns (uint256) {
        return montant_cumuldesprimes *40/100;
    }
    
    //affiche le montant attribuer à la réserve en fin d'annéee s'il existe de l'argent dans le fond commun 
    function reserve (uint montant_reserve) public view versement_reserve returns (uint) {
        if (montant_reserve >0) {
            return montant_reserve*60/100;
        }else {
            return 0;
        }    
    }
    
    //affiche le resultat de votation
    function resultat_votation () public view temps_ecoule2 returns (uint) {
      if (votes[1]>7) return 1;
      if (votes[1]<=7) return 0;
    }
    
    //permet de retirer le montant si la demande a été accetpée 
   function retirermontant(uint montant) public payable demandeRefusee   {
    prime[msg.sender]-=montant;
     msg.sender.transfer(montant);
    }     
    
    //permet de retirer le montant de la fonction giveback 
    function retraitGiveBack (uint montant) public payable impossibleDeRetirer (montant){
        prime[msg.sender]-=montant*10/100;
        msg.sender.transfer(montant*10/100);
        }
    
     //permet de voir la prime d'un assuré spécifique 
    function voirprime (address assure) public view returns(uint) {
        return prime [assure];
    }
    
    //permet de  voir le nombre de voix pour et le nombre de voix contre la demande de remboursement 
    function voirVotes () public view returns (uint [2] memory) {
        return votes;
    }
    
     //permet de voter pour ou contre la demande de remboursement de l'assure lese 
     function voter (uint decision_de_vote) public propositionValide(decision_de_vote)   temps_ecoule aDejaVote { 
        votes[decision_de_vote] =  votes[decision_de_vote] + 1;
        vote[msg.sender]=true;
    }
}