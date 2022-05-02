/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;




contract test {
    event Log(bool sent);

    bool public myBool = false;
    address public myContract;

    function setMyContract(address addy) public { 
        myContract = addy;
    }

    // Testing to see the behavior when these methods of sending Eth fail

    function sendEthUsingTransfer() public payable { // Check balance in second contract to see if it was snet
        payable(myContract).transfer(msg.value); // This is equivalent to require(payable(myContract).send(msg.value)); and will throw an error when it fails, reverting the whole transaction.
    }

    function sendEthUsingCall() public payable {
        (bool sent, ) = payable(myContract).call{value: msg.value}("");
        emit Log(sent); // Emitting to see if the transaction was sent. 
    }

    function sendEthUsingSend() public payable {
        (bool sent) = payable(myContract).send(msg.value);
        emit Log(sent);
    }
}