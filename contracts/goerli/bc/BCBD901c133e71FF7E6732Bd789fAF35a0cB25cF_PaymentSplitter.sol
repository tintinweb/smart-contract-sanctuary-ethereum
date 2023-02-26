// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract PaymentSplitter {
    address public owner;
    uint256 public ownerCut = 15; // 10% owner cut
    uint256 public companyCut = 85; // 90% company cut

    constructor() {
        owner = msg.sender;
    }

    function sendPayment(address payable receiver) public payable {
        require(msg.value > 0, "Payment amount must be greater than 0");
        require(msg.sender != address(0), "Invalid sender address");
        require(receiver != address(0), "Invalid receiver address");

        // transfer ownerscut to owner
        uint256 ownerAmount = (msg.value * ownerCut) / 100;
        // transfer companycut to receiver
        uint256 companyAmount = (msg.value * companyCut) / 100;
        //check for remainder
        uint256 remainder = msg.value - (ownerAmount + companyAmount);

        require(remainder == 0, "Invalid amount");

        // send eth from contract to owner
        payable(owner).transfer(ownerAmount);

        // send eth from contract to receiver
        receiver.transfer(companyAmount);
    }

    function changeOwnerShare(uint256 _ownerShare) public {
        require(msg.sender == owner, "Only the owner can change the owner cut");
        ownerCut = _ownerShare;
        companyCut = 100 - ownerCut;
    }

    function changeOwner(address payable _owner) public {
        require(
            msg.sender == owner,
            "Only the owner can change the owner address"
        );
        owner = _owner;
    }
}