/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: No license

pragma solidity 0.8.12;

contract UnlockFunds {
    uint256 public modulo = 2;
    address payable public recipient;

    constructor(address payable _user) {
        recipient = _user;
    }

    function deposit() public payable {}

    function unlockEth(uint256 password) public {
        require(msg.sender == recipient);

        uint256 tryPassword = uint256(keccak256(abi.encodePacked(recipient, password)));
        require(tryPassword % modulo == 0);

        uint balance = address(this).balance;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Failed to send Ether");
    }

    function testHash(uint256 password) public view returns(uint256) {
        uint256 tryPassword = uint256(keccak256(abi.encodePacked(recipient, password)));
        return tryPassword % modulo;
    }
}