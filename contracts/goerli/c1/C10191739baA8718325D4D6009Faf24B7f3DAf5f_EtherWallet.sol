// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract EtherWallet {
    event Log(string func, uint gas);
    address _owner;
    constructor()  {
       _owner=msg.sender;  
    }
    // Fallback function must be declared as external.
    fallback() external payable {
        // send / transfer (forwards 2300 gas to this fallback function)
        // call (forwards all of the gas)
        emit Log("fallback",gasleft());
    }
    function withdraw() external payable {
              // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        require(msg.sender==_owner,"nO");
        emit Log("value",msg.value);
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }


    // Receive is a variant of fallback that is triggered when msg.data is empty
    // receive() external payable {
    //     emit Log("receive", 222);
    // }
    function getBalance() external view returns(uint){
        return address(this).balance;
    }
  
}