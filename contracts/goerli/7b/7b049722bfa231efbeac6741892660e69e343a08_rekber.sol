/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

contract rekber {

    event Approved(uint);

    address public oldManJenkins; // address buyer
    address public karen; // address rekber/penengah
    address public mrKrabs; // address seller
    bool public isApproved; // status rekber, default: false
    uint public funding; // nyimpen balance contract

    constructor(address _karen, address _mrKrabs) payable {
        oldManJenkins = msg.sender;
        karen = _karen;
        mrKrabs = _mrKrabs;
        funding = address(this).balance;
    }

    function approve() external {
        require(karen == msg.sender);
        (bool sent, ) = mrKrabs.call{value: funding}("");
        require(sent);
        isApproved = true;
        emit Approved(funding);
        funding = address(this).balance;
    }

}