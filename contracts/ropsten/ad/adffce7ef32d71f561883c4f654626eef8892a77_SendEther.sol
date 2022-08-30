/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface SanctionsList {
    function isSanctioned(address addr) external view returns (bool);
}

contract SendEther {
    address constant SANCTIONS_CONTRACT = 0x40C57923924B5c5c5455c48D93317139ADDaC8fb;
    /*
    function sendViaTransfer(address payable _to) public payable {
        // This function is no longer recommended for sending Ether.
        _to.transfer(msg.value);
    }

    function sendViaSend(address payable _to) public payable {
        // Send returns a boolean value indicating success or failure.
        // This function is not recommended for sending Ether.
        bool sent = _to.send(msg.value);
        require(sent, "Failed to send Ether");
    }
*/
    function sendViaCall(address payable _to) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.

        SanctionsList sanctionsList = SanctionsList(SANCTIONS_CONTRACT);
        bool isToSanctioned = sanctionsList.isSanctioned(_to);
        require(!isToSanctioned, "Transfer to sanctioned address");

        uint amount = msg.value / 3;
        (bool sent1, ) = _to.call{ value: amount }("");
        require(sent1, "Failed to send Ether");
        (bool sent2, ) = _to.call{ value: amount }("");
        require(sent2, "Failed to send Ether");
    }

    function withdraw() public {
    //   payable(owner()).transfer(address(this).balance);
      (bool sent1, ) = msg.sender.call{ value: address(this).balance }("");
      require(sent1, "Failed to send Ether");
    }
}