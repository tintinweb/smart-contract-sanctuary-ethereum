//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.2;

contract TensetPayments {
    address public destination;
    uint256 public id;

    event PaymentReceived(address indexed account, string refId, uint256 id, uint256 amount);

    /**
    @param destination_ - wallet address which pays out rewards
    */
    constructor(address destination_) {
        destination = destination_;
    }

    /**
    @param refId reference to item for which payment is made
    */
    function pay(string memory refId) public payable {
        require(msg.value > 0, "Amount must be greater than zero");
        require(msg.sender != address(0), "Transfer account the zero address");
        (bool sent, ) = payable(destination).call{ value: msg.value }("");
        require(sent, "Failed to transfer payment");
        uint256 id_ = ++id;
        emit PaymentReceived(msg.sender, refId, id_, msg.value);
    }
}