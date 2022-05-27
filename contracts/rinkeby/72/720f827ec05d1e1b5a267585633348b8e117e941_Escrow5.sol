/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Escrow5 {

    event StateChange(address indexed NFT, uint256 indexed id, State);
    event EscrowCreated(address indexed NFT, uint256 indexed id, uint256 price, address seller);
    event EscrowFufilled(address indexed NFT, uint256 indexed id, uint256 price, address seller, address buyer);
    event transferAmounts(uint256 sellerAmount, uint256 pandoWalletAmount);
    enum State {INITIAL_STATE, AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE} 


    struct escrowInfo{
        address seller;
        address NFT;
        uint256 index;
        uint256 price;
        State escrowState;
        address buyer;
    }

    mapping(address => mapping(uint256 => escrowInfo)) Ecrows; //Map from NFT address and NFT index to escrow information

    address payable public pandoWallet; 
    uint256 pandoPercentage; //If desire 95% goes to seller, than set `pandoPercentage` to 9500.
    constructor(address _pandoWallet, uint256 _pandoPercentage){
        pandoWallet = payable(_pandoWallet);
        pandoPercentage = _pandoPercentage;
    }

    //Seller creates Escrow, sends NFT to this contract, and dictates price
    function createEscrow(address NFT, uint256 index, uint256 price) external{
        //TODO: Seller sends NFT to this contract
        require(price >= 0, "Price must be greater than 0");
        require(Ecrows[NFT][index].escrowState == State.INITIAL_STATE, "NFT must be in Initial State to create new escrow");   

        Ecrows[NFT][index] = escrowInfo(msg.sender, NFT, index, price, State.AWAITING_PAYMENT, 0x0000000000000000000000000000000000000000); //Set the information for the escrow
        emit StateChange(NFT, index, State.AWAITING_PAYMENT);
        emit EscrowCreated(NFT, index, price, msg.sender);
    }

    function confirmPayment(address NFT, uint256 index) external payable { //Buyer sends funds to escrow contract 
        require(Ecrows[NFT][index].escrowState == State.AWAITING_PAYMENT, "Escrow must have been created for NFT");
        Ecrows[NFT][index].escrowState = State.AWAITING_DELIVERY;
    
        uint256 price = Ecrows[NFT][index].price; //Retrieve price of NFT
        require(msg.value >= price, "Not enough Ether sent");   //TODO: Best to set this as `msg.value ==  price`, so that no extra ETH can be locked in the contract after confirmDelivery is called.

        //Set buyer/investor of NFT to msg.sender
        Ecrows[NFT][index].buyer = msg.sender;

        emit StateChange(NFT, index, State.AWAITING_DELIVERY);
    }

    function confirmDelivery(address NFT, uint256 index) external payable { //contract releases NFT to buyer, and contract releases payment to seller

        //TODO: require(msg.sender == Ecrows[NFT][index].seller, "Only NFT seller can call this function")
        require(Ecrows[NFT][index].escrowState == State.AWAITING_DELIVERY, "Escrow must be in awaiting delivery state");
        
        //TODO: Transfer NFT to buyer
        Ecrows[NFT][index].escrowState = State.INITIAL_STATE; //Reset state so that a new Escrow can be created for the NFT.

        address seller = Ecrows[NFT][index].seller;

        uint256 amountToSeller = Ecrows[NFT][index].price  * pandoPercentage / 10000; 
        uint256 amountToPando = (Ecrows[NFT][index].price ) - amountToSeller; 
        payable(seller).transfer(amountToSeller); //Send funds to the seller address
        payable(pandoWallet).transfer(amountToPando); //Send Pando fee to Pando address

        emit StateChange(NFT, index, State.INITIAL_STATE);
        emit EscrowFufilled(NFT, index, Ecrows[NFT][index].price, Ecrows[NFT][index].seller, msg.sender);
        emit transferAmounts(amountToSeller, amountToPando);
    }
 
    function declinePendingOffer(address NFT, uint256 index) external{

        //TODO: require(msg.sender == Ecrows[NFT][index].seller || msg.sender == Ecrows[NFT][index].buyer, "Only NFT seller/buyer can call this function")
        require(Ecrows[NFT][index].escrowState == State.AWAITING_DELIVERY, "Escrow must be in awaiting delivery state");

        //TODO: Transfer NFT back to investor
        Ecrows[NFT][index].escrowState = State.INITIAL_STATE; //Reset state so that a new Escrow can be created for the NFT.

        address buyer = Ecrows[NFT][index].buyer;
        //Send payment back to the buyer
        payable(buyer).transfer(Ecrows[NFT][index].price);

    }

    function balanceInContract() view external returns(uint256) {
        uint256 balance = address(this).balance;
        return balance;
    }
}