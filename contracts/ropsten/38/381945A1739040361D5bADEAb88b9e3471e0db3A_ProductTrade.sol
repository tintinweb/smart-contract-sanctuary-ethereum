// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ProductTrade {
    address public owner;
    address public buyer;
    string public productName;
    uint256 public productPrice;
    uint256 public contractBalance;
    bool public receptionApproved;
    bool public returnApproved;
    TXN_STATE public txn_state;

    constructor(
        string memory _productName,
        uint256 _productPrice,
        address _owner
    ) {
        productName = _productName;
        productPrice = _productPrice;
        owner = _owner;
        txn_state = TXN_STATE.FOR_SALE;
    }

    enum TXN_STATE {
        FOR_SALE,
        PURCHASED,
        RETURN,
        CLOSED
    }

    function startReturn() public payable {
        require(msg.sender == buyer);
        require(txn_state == TXN_STATE.PURCHASED);
        txn_state = TXN_STATE.RETURN;
    }

    function buyProduct() public payable {
        require(txn_state == TXN_STATE.FOR_SALE, "Item is not up for sale.");
        require(
            msg.value >= productPrice,
            "Transaction value too low for purchase of this item."
        ); // Ensure that the buyer does not purchase the product for the wrong price.
        buyer = msg.sender;
        contractBalance += msg.value;
        txn_state = TXN_STATE.PURCHASED;
    }

    function approveReception() public returns (bool) {
        require(txn_state == TXN_STATE.PURCHASED);
        require(
            msg.sender == buyer,
            "Only the buyer can approve the reception of the product."
        );
        receptionApproved = true;
        return receptionApproved;
    }

    function approveReturn() public returns (bool) {
        require(txn_state == TXN_STATE.RETURN);
        require(
            msg.sender == owner,
            "Only the seller can approve the return of the product."
        );
        returnApproved = true;
        return returnApproved;
    }

    function getState() public view returns (uint8) {
        return uint8(txn_state);
    }

    function withdraw() public {
        require(
            owner != address(0) && buyer != address(0),
            "Cannot withdraw to the zero address."
        );
        if (returnApproved && msg.sender == buyer) {
            payable(address(buyer)).transfer(address(this).balance);
            contractBalance = 0;
            txn_state = TXN_STATE.CLOSED;
        } else if (receptionApproved && msg.sender == owner) {
            payable(address(owner)).transfer(address(this).balance);
            contractBalance = 0;
            txn_state = TXN_STATE.CLOSED;
        } else {
            revert();
        }
    }
}