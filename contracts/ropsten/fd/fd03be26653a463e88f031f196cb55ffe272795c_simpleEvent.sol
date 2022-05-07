/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

pragma solidity ^0.8.0;

//SPDX-License-Identifier: 3

contract simpleEvent{
    
    address owner;

    constructor() {
        owner = msg.sender;
        //address who create transaction is the owner address.
    }

    event TokensSent(address _from, address _to);

    uint public balance ;

    function receiveFunds () payable public
    {
        balance += msg.value;
    }


    function withdrawMoney(address receiverAddress) public returns(bool)
    {
        require(msg.sender == owner, "You are not the owner, not authorised to withdraw");
        address payable receiver = payable(receiverAddress);
        balance = 0;
        receiver.transfer(address(this).balance);

        emit TokensSent(msg.sender, receiverAddress);
        return true;
    }

}