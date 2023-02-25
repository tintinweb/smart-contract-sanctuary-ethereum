// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract PaymentSplitter {
    address public owner;
    uint256 public ownerCut = 10; // 10% owner cut
    uint256 public companyCut = 90; // 90% company cut

    constructor() {
        owner = msg.sender;
    }

    function sendPayment(address payable receiver) public payable {
        require(msg.value > 0, "Payment amount must be greater than 0");
        require(msg.sender != address(0), "Invalid sender address");
        require(receiver != address(0), "Invalid receiver address");
        require(msg.value > 0.0008 ether, "Not enough ETH to pay gas");

        uint256 new_value = msg.value - 0.0008 ether;

        uint256 ownerAmount = (new_value * ownerCut) / 100;
        uint256 companyAmount = (new_value * companyCut) / 100;
        uint256 remainder = new_value - (ownerAmount + companyAmount);

        require(remainder == 0, "Invalid amount");

        // send eth from contract to owner
        payable(owner).transfer(ownerAmount + 0.0008 ether);

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