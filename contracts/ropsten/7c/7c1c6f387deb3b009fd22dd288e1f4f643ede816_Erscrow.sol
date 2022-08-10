/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

//SPDX-License-Identifier: MIT
pragma solidity^0.8.7;


contract Erscrow{

    address payable public Sender;
    address payable public  Receiver;
    uint public price;

    bool public IsSenderready;
    bool public isReceiverready;

    constructor(address payable _Sender, address payable _Receiver, uint _price){
        Sender = _Sender;
        Receiver = _Receiver;
        price = _price * 0.1 ether;
    }

    modifier onlySender() {
        require(msg.sender == Sender, "Only Sender can call this function");

        _;
    }

    modifier onlyReceiver() {
        require(msg.sender == Receiver, "Only Receiver can call this function");

        _;
    }
  // Sender can call this function and agree for escrow service
    function Senderagree() public onlySender {
        IsSenderready = true;
    }

    function ReceiverAgree() public onlyReceiver{
        isReceiverready =  true;
    }

    function deposit() public payable onlySender {
        require(IsSenderready == true);
        require(isReceiverready == true);
        require(msg.value == price);
    }

    function Complete() public payable onlySender{
        Receiver.transfer(price);
    }

    function withdraw() public payable onlySender{
        Sender.transfer(price);
    }



}