//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract BlockStream{
    /* Take home a movie theater
    *  How to:
    *    1: connect your wallet to the stream app
    *       stream app reads the public key of your wallet and set your subscription number
    *    2: scan the QR code (address of the BlockStream) and pay with a crypto wallet
    *    3: add the BlockStream address to your crypto wallet and reuse it
    *  After doing a payment, our service assigns time to the subscription number
    *
    *  Plug and Play: Connect the stream app to the Home Smart TV and watch the movie
    *  General Data Protection: Illegal videos are nowhere to be found on this media (suitable for all ages)
    */
    event transfer_to_parent(uint timestamp, address sender, uint value);
    
    mapping(address => bool) mutex;
    address payable parent;

    constructor(address payable _parent){
        parent = _parent;
    }

    fallback()external payable{
        transfer();
    }
    receive()external payable{
        transfer();
    }

    function transfer() internal{
        require(msg.value > 0,'no payment');
        require(mutex[msg.sender] != true,'reject reentrancy');
        mutex[msg.sender] = true;
        (bool succeed,) = payable(parent).call{value: msg.value}("");
        require(succeed, "transfer to the parent failed");
        emit transfer_to_parent(block.timestamp, msg.sender, msg.value);
        mutex[msg.sender] = false;
    }
}