/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract DataSubmitter {
    address payable paymentAddress;
    address owner;

    constructor() {
        // Define owner when deploying contract;
        owner = msg.sender;
    }

    event Published(address publisher, string dataHash);

    // Function to submit data and 0.01 ETH payment
    function submitData(string memory _data) public payable {
        // Check if the user paid at least 0.01 ETH
        require(msg.value >= 1 wei, "Insufficient payment.");
        // Create even logs with submitted data
        emit Published(msg.sender, _data);
    }

    // Function to check balance in this contract
    function checkBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Function for owner to withdraw ETH from contract
    function withdraw() public {
        require(msg.sender == owner, "Only the owner of this contract can withdraw funds.");
        require(address(this).balance > 0, "No funds to withdraw.");
        paymentAddress.transfer(address(this).balance);
    }

    // Function to set new owner address
    function setOwner(address _newOwner) public {
        require(msg.sender == owner, "Only the current owner can change the owner address.");
        owner = _newOwner;
    }

    // Function to set new payment address
    function setPaymentAddress(address payable _newPaymentAddress) public {
        require(msg.sender == owner, "Only the current owner can change the payment address.");
        paymentAddress = _newPaymentAddress;
    }

    // mapping to record entry count by wallet
    mapping(address => uint) public entryCount;

    // function to set entry count
    function incrementEntryCount() private {
        entryCount[msg.sender] ++;
    }

    function getEntryCount(address _addr) public view returns (uint) {
        return entryCount[_addr];
    }

}