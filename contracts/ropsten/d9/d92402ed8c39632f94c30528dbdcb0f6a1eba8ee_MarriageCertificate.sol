/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract MarriageCertificateCreator {

    MarriageCertificate[] public certificates;
    address payable public owner;
    uint public certificateFee;
    string[3] public lastMarriage;
    
    constructor() {
        owner = payable(msg.sender);
        certificateFee = 100000000000000000 wei;
    }
    
    event LogNewCertificateCreated(MarriageCertificate newCertificateAddress, uint numberOfCertificates);
    
    modifier onlyOwner {
        require(msg.sender == owner, "Vous ne pouvez pas effectuer cette action.");
        _;
    }
    
    function createNewCertificate(
        string memory spouse1, string memory spouse2, address spouse2address, string memory location
        ) public payable {
        // Les frais doivent être payés
        require(msg.value >= certificateFee, "Frais insuffisants.");
        // Nouvelle création de certificat
        MarriageCertificate newCertificate = new MarriageCertificate(
            msg.sender,
            spouse1,
            spouse2,
            spouse2address,
            location);
        // On sauve l'adresse dans un tableau
        certificates.push(newCertificate);
        // On met à jour le tableau de derniers mariages
        lastMarriage = [spouse1, spouse2, location];
        // On retourne un event pour l'interface Web3
        emit LogNewCertificateCreated(newCertificate, certificates.length);
    }
    
    /// @dev Le propriétaire du contrat peut update les frais requis pour créer un nouveau certificat
    function updateFee(uint newFee) public onlyOwner {
        certificateFee = newFee;
    }
    
    function returnNumberOfContracts() public view returns (uint) {
        return certificates.length;
    }
    
    function getLastMarriage() public view returns (string memory, string memory, string memory) {
        return (lastMarriage[0], lastMarriage[1], lastMarriage[2]);
    }
    
    function returnBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }
    
    function close() public onlyOwner {
        owner.transfer(address(this).balance);
        selfdestruct(owner);
    }
    
    fallback() external payable {}
        receive() external payable {}
}

contract MarriageCertificate {
    string public location;
    string public spouse1;
    string public spouse2;
    bool[2] public isValid;
    address[2] public spousesAddresses;
    uint public timestamp;
    mapping(bytes32 => uint) public accounts;
    struct withdrawRequestFromSavings {
        address payable sender;
        uint amount;
        uint timestamp;
        bool approved;
    }
    mapping(uint => withdrawRequestFromSavings) public withdrawRequests;
    uint public version;
    
    event LogMarriageValidity(bool[2] validity);
    event LogNewWithdrawalRequestFromSavings(uint request);
    event LogBalance(uint total, uint joint, uint savings);
    
    constructor (
        address certificateCreator, 
        string memory _spouse1, 
        string memory _spouse2,
        address spouse2address, 
        string memory _location) {
        require(certificateCreator != spouse2address, "Les adresses des conjoints ne peuvent pas etre les memes.");
        
        location = _location;
        spouse1 = _spouse1;
        spouse2 = _spouse2;
        isValid = [true, false];
        spousesAddresses = [certificateCreator, spouse2address];
        timestamp = block.timestamp;
        accounts["joint"] = 0;
        accounts["savings"] =  0;
        version = 1;
    }
    
    /// @dev certaines fonctions ne peuvent être utilisées que par un des deux conjoints
    modifier onlySpouses {
        require (
            msg.sender == spousesAddresses[0] || msg.sender == spousesAddresses[1], "Le statut du contrat ne peut etre modifie que par les conjoints concernes."
            );
        _;
    }
    
    function checkIfValid() public view returns (bool, bool) {
        return (isValid[0], isValid[1]);
    }
    
    function returnSpousesAddresses() public view returns (address, address) {
        return (spousesAddresses[0], spousesAddresses[1]);
    }
    
    /// @dev Seul un des deux conjoints a accès à cette fonction
    function returnBalances() public view returns (uint, uint, uint) {
        return (address(this).balance, accounts["joint"], accounts["savings"]);
    }
    
    /// @notice Permet aux conjoints de changer l'état du contrat
    function changeMarriageStatus() public onlySpouses {
        if(msg.sender == spousesAddresses[0]){
            isValid[0] = !isValid[0];
        } else if(msg.sender == spousesAddresses[1]){
            isValid[1] = !isValid[1];
        }
        
        emit LogMarriageValidity(isValid);
    }
    
    /// @notice Permet aux conjoints ou à des tierces personnes de faire un dépôt d'argent dans le contrat de mariage.
    function deposit(uint amount, bytes32 account) public payable onlySpouses {
        // On vérifie que le montant envoyé est le montant requis
        require(msg.value == amount, "Mauvais montant envoye.");
        // On met à jour le solde en fonction du type de compte sélectionné
        if(stringsAreEqual(account, "joint")) {
            accounts["joint"] += amount;
        } else if(stringsAreEqual(account, "savings")) {
            accounts["savings"] += amount;
        } else {
            revert("Ce n'est pas un compte valide.");
        }
        // On vérfiei que le joint et le total des economies est égal au montant total
        assert(accounts["joint"] + accounts["savings"] == address(this).balance);
        // On log le nouveau solde
        emit LogBalance(address(this).balance, accounts["joint"], accounts["savings"]);
    }
    
    /// @notice Permet aux conjoints de retirer de l'argent du compte
    function withdraw(uint amount, bytes32 account) public onlySpouses {
        require(accounts[account] >= amount, "La demande depasse le montant du solde.");
        
        // On regarde si le solde est assez grand pour retirer du compte joint.
        if(stringsAreEqual(account, "joint") && 
            accounts["joint"] >= amount) {
            // On soustrait le montant du montant du compte joint.
            accounts["joint"] -= amount;
            // On envoie l'argent.
            payable(msg.sender).transfer(amount);
        } else if(stringsAreEqual(account, "savings") && 
            accounts["savings"] >= amount) {
            // On créé un numéro de requête
            uint requestID = uint(timestamp + block.difficulty + block.number);
            // On sauvegarde la nouvelle requête dans le mapping des requêtes
            withdrawRequests[requestID] = withdrawRequestFromSavings({
                sender: payable(msg.sender),
                amount: amount,
                timestamp: timestamp,
                approved: false
            });
            // On émet la nouvelle requête avec un ID qui aidera à le retrouver dans le mapping des requêtes
            emit LogNewWithdrawalRequestFromSavings(requestID);
        } else {
            revert("Compte invalide ou montant de la requete excedant le solde disponible.");
        }
        // On vérifie que le montant du compte joint et les économies sont égales au solde total.
        assert(accounts["joint"] + accounts["savings"] == address(this).balance);
        // On log le souveau solde.
        emit LogBalance(address(this).balance, accounts["joint"], accounts["savings"]);
    }
    
    function approveWithdrawRequestFromSavings(uint requestID) public onlySpouses {
        withdrawRequestFromSavings storage request = withdrawRequests[requestID];
        // On teste si la requête existe
        require(request.timestamp > 0 && request.amount > 0, "Cette requete n'existe pas.");
        // On vérifie qu'il y ait assez de fonfs à retirer.
        require(request.amount <= accounts["savings"], "Il n'y a pas assez de fonds pour proceder a cette requete.");
        // La requête ne peut pas être approuvée avant.
        if(request.approved == false) {
            // Le conjoint approuvant la requête ne peut pas être celui qui l'a initié.
            if((spousesAddresses[0] == msg.sender && spousesAddresses[1] == request.sender) || 
            (spousesAddresses[1] == msg.sender && spousesAddresses[0] == request.sender)) {
                // Marque la requête comme approuvée.
                request.approved = true;
                // On déduit le montant du mapping des comptes.
                accounts["savings"] -= request.amount;
                // On transfère l'argent
                request.sender.transfer(request.amount);
                // On vérifie que le montant du compte joint et des économies est égal au montant total.
                assert(accounts["joint"] + accounts["savings"] == address(this).balance);
                // On log le nouveau solde
                emit LogBalance(address(this).balance, accounts["joint"], accounts["savings"]);
            } else {
            revert("La requete ne peut pas etre approuvee par la personne qui l'a creee.");
            }
        } else {
            revert("Cette requete a deje ete approuvee.");
        }
    }
    
    /// @notice Permets aux conjoints d'utiliser le montant de dépôt pour les paiements.
    function pay(address payable _address, uint amount) public onlySpouses {
        require(amount <= accounts["joint"], "Il n'y a assez de fonds pour proceder a la transaction.");
        
        accounts["joint"] -= amount;
        // On transfère l'argent à l'adresse fournie.
        _address.transfer(amount);
        // On vérfiei que le montant du compte joint et les économie soient égales au montant total.
        assert(accounts["joint"] + accounts["savings"] == address(this).balance);
        // On log le nouveau solde
        emit LogBalance(address(this).balance, accounts["joint"], accounts["savings"]);
    }
    
    /// @notice fonction de fallback pour envoyer de l'argent directmeenr, l'argent stocké dans le compte de dépôt par défaut.
    fallback() external payable {
        accounts["joint"] += msg.value;
    }
    receive() external payable {}
    
    function closeCertificate() public onlySpouses {
        // On transforme les adresses des conjoints en adresse de paiement
        address _spouse1address = address(uint160(spousesAddresses[0]));
        address _spouse2address = address(uint160(spousesAddresses[1]));
        // On transfère la moitié du solde à chaque conjoint
        payable (_spouse1address).transfer(address(this).balance/2);
        payable (_spouse2address).transfer(address(this).balance);
        // On détruit le contract et on envoie les "weis" restants au conjoint ayant créé le contrat.
        selfdestruct(payable(_spouse1address));
    }

    /// @dev On compare deux chaînes
    function stringsAreEqual(bytes32 str1, bytes32 str2) pure private returns (bool) {
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }
}