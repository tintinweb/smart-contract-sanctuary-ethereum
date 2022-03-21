// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

/**
 * @title Payments. Management of payments
 * @dev Provide functions for payment and withdraw of funds. Stores payments.
 */
contract Payments {
    address payable owner;

    // Log of payments
    mapping (address=>Payment[]) private payments;

    struct Payment {
        string id;
        uint amount;
        uint256 date;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    // Event to notify payments
    event Pay(address, string, uint);

    // Optional. a fallback function
    fallback() external payable {
        require(msg.data.length == 0, "The called function does not exist");
    }
    
    receive() external payable {
        require(msg.value > 0, "The transaction value");
        owner.transfer(msg.value);
    }

    function pay(string memory id, uint value) public payable {
        require(msg.value == value, "The Payment does not match the transaction value");
        payments[msg.sender].push(Payment(id, msg.value, block.timestamp));

        emit Pay(msg.sender, id, msg.value);
    }

    /**
     * @dev `withdraw` Withdraw funds to the owner of the contract
     */

    function withdraw() public payable {
        require(msg.sender == owner, "Only owners can withdraw funds");
        owner.transfer(address(this).balance);
    }

    /**
     * @dev `paymentsOf` Number of payments made by an account
     * @param  buyer Account or address
     * @return number of payments
     */
    function paymentOf(address buyer) public view returns (uint) {
        return payments[buyer].length;
    }

    function paymentOfAt(address buyer, uint256 index) public view returns (string memory id, uint amount, uint256 date) {
        Payment[] memory pays = payments[buyer];
        require(pays.length > index, "Payment does not exist.");
        Payment memory payment = pays[index];

        return (payment.id, payment.amount, payment.date);
    }

}