/**
 *Submitted for verification at Etherscan.io on 2023-03-15
*/

pragma solidity ^0.4.2;

contract EscrowContract {

    //set variables
    address public buyer;
    address public seller;

    //constructor runs once
    constructor(address _buyer, address _seller){
        buyer = _buyer;
        seller = _seller;
    }

    function () public payable {
    }

    //make payment to seller
    function payoutToSeller() {
        if(msg.sender == buyer) {
        if(!seller.send(this.balance)) throw;
        }
    }

    //refund transaction
    function refundToBuyer() {
        if(msg.sender == seller) {
        if(!buyer.send(this.balance)) throw;
        }
    }

    //query for balance
    function getBalance() constant returns (uint) {
        return this.balance;
    }

}