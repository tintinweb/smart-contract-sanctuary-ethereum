/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow4 {

    event StateChange(address indexed NFT, uint256 indexed id, State);
    event EscrowCreated(address indexed NFT, uint256 indexed id, uint256 price, address seller);
    event EscrowFufilled(address indexed NFT, uint256 indexed id, uint256 price, address seller, address buyer);
   
    enum State { INITIAL_STATE, AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE} 


    struct escrowInfo{
        address seller;
        address NFT;
        uint256 index;
        uint256 price;
        State escrowState;
    }

    mapping(address => mapping(uint256 => escrowInfo)) Ecrows; //Map from NFT address and NFT index to ecrow information


    //Seller creates Escrow, sends NFT to this contract, and dictates price
    function createEscrow(address NFT, uint256 index, uint256 price) external{
        //TODO: Seller sends NFT to this contract
        require(price >= 0, "Price must be greater than 0");
        require(Ecrows[NFT][index].escrowState == State.INITIAL_STATE, "NFT must be in Initial State to create new escrow");   

        Ecrows[NFT][index] = escrowInfo(msg.sender, NFT, index, price, State.AWAITING_PAYMENT); //Set the information for the ecrow
        emit StateChange(NFT, index, State.AWAITING_PAYMENT);
        emit EscrowCreated(NFT, index, price, msg.sender);
    }

    function confirmPayment(address NFT, uint256 index) external payable { //Buyer sends funds to escrow contract 
        require(Ecrows[NFT][index].escrowState == State.AWAITING_PAYMENT, "Ecrow must have been created for NFT");
        Ecrows[NFT][index].escrowState = State.AWAITING_DELIVERY;

        uint256 price = Ecrows[NFT][index].price; //Retrieve price of NFT
        require(msg.value >= price, "Not enough Ether sent");
        emit StateChange(NFT, index, State.AWAITING_DELIVERY);
    }

    function confirmDelivery(address NFT, uint256 index) external payable { //contract releases NFT to buyer, and contract releases payment to seller

        require(Ecrows[NFT][index].escrowState == State.AWAITING_DELIVERY, "Ecrow must be in awaiting delivery state");
        
        //TODO: Transfer NFT to buyer
        Ecrows[NFT][index].escrowState == State.INITIAL_STATE; //Reset state so that a new Ecrow can be created for the NFT.

        address seller = Ecrows[NFT][index].seller;
        payable(seller).transfer(Ecrows[NFT][index].price); //Send funds to the seller address
        emit StateChange(NFT, index, State.INITIAL_STATE);
        emit EscrowFufilled(NFT, index, Ecrows[NFT][index].price, Ecrows[NFT][index].seller, msg.sender);
    }

    function balanceInContract() view external returns(uint256) {
        uint256 balance = address(this).balance;
        return balance;
    }
}