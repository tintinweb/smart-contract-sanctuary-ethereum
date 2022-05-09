/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

// SPDX-License-Identifier: None
pragma solidity 0.8.4;

contract Wallet {

    //define addresses that will be allowed to multi-sig
    address[] public approvers;
    //define quorum = ammount of address that are needed to multisig the transaction (exemple: 2/3, 3/3, ..)
    uint public quorum;
    //on définit une struc avec les différentes informations nécessaires sur un transfert:
    // un id pour les transaction, le montant, le recipient, le nombre de personnes qui ont approuvé la tx, le statut de la tx isSent?
    struct Transfer {
        uint id;
        uint amount;
        address payable to;
        uint approvals;
        bool sent;
    }
    
    //on déclare ensuite un mapping avec en clefs les id des tx et en valeur la struct. ce mapping est un container qui va recevoir toutes les tx:
    
    //     mapping(uint => Transfer) public transfers;

    //puis un entier pour dire quelle sera la valeur du prochain id de tx:

    //     uint public nextId;

    //en réalité, l'array est plus efficace que la mapping, c'est pourquoi il a été remplacé par l'array suivant:

    Transfer[] public transfers;

    //create a mapping to state who approve the Transfer, through a nested mapping:
    mapping(address => mapping(uint => bool)) public approvals;

    //define argument with _ when you don't want to shadow the approvers variable
    constructor(address[] memory _approvers, uint _quorum)  {
        approvers = _approvers;
        quorum = _quorum;
    }

    //même si solidity va créer une fonction qui permets de lire la tableau approvers puisqu'elle la variable est déclarer en public
    //nous allons quand même déclarer une fonction getApprovers car le rendu n'est pas le même
    function getApprovers() external view returns(address[] memory) {
        return approvers;
    }

    function getTransfers() external view returns(Transfer[] memory) {
        return transfers;
    }

    //fonction qui crée le transfert, celle ci utilise le précédent mapping déclaré (et commenté //), on utilisera donc la fonction d'après:

    //     function createTransfer(uint amount, address payable to) external {

        //on écrit dans notre mapping, clef = id de la tx , valeur = struct Transfer:

       //      transfers[nextId] = Transfer(
            //     nextId,
            //     amount,
            //     to,
            //     0,
            //     false
        //     );

        //on finit par incrémenter nextID pour que la transaction d'après, n'overwrite pas la précédente:

        //     nextId++;
    //     }
    
    //ci-dessous la fonction createTransfer utilisant notre array:

    function createTransfer(uint amount, address payable to) external onlyApprover(){
        transfers.push(Transfer(
            transfers.length,
            amount,
            to,
            0,
            false
        ));
    }

    function approveTransfer(uint id) external onlyApprover(){
        // make sure the transfer hasn't already been sent:
        require(transfers[id].sent == false, 'transfer has already been sent');
        //check if the sender of the tx has already approve the transfer, cause you can't approve a transfer twice:
        require(approvals[msg.sender][id] == false, "can't approve transfer twice");
        //set the approval for this address to true:
        approvals[msg.sender][id] = true;
        //increment the number of approval in our Transfer
        transfers[id].approvals++;

        //send the transfer if we have enough approval:
        if(transfers[id].approvals >= quorum) {
            transfers[id].sent = true;
            address payable to = transfers[id].to;
            uint amount = transfers[id].amount;
            //the next transfer method has nothing to deal about our transfer it's a method attached to every payable addresses to send eth:
            to.transfer(amount);
        }

    }

    //rendre le contrat able to receive some ether in order to act as a wallet:
    //this is one way,
    function sendEther() external payable {

    }

    //but this way is better, this function will be triggereed automaticaly once someone call the SC without any function (like sending some eth on for example):
    receive() external payable {

    }

    //actuellement tout le monde peut approve le contrat et appeler les fonctions => PAS TOP! 
    //mais avec ce modifier ajouté aux fonctions, seules les addresses autorisées le pourront
    modifier onlyApprover() {
        bool allowed = false;
        for(uint i = 0; i < approvers.length; i++){
            if(approvers[i] == msg.sender) {
                allowed = true;
            }
        }
        require(allowed == true, 'only approvers allowed');
        _;
    }


}