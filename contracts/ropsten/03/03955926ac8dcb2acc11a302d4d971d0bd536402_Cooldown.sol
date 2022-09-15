/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Cooldown {
    /// The Order struct
    struct Order {
        address sender;
        address receiver;
        uint256 amount;
        uint256 deadline;
        OrderStatus status;
        UserStatus senderStatus;
        UserStatus receiverStatus;
    }

    // Enum status of order
    enum OrderStatus {
        Pending,
        Completed,
        Confirmed,
        Canceled
    }

    // Enum status of order
    enum UserStatus {
        OK,
        NOK,
        CANCEL
    }

    /// The mapping to store orders
    mapping(uint256 => Order) public orders;

    /// The sequence number of orders
    uint256 orderseq;

    event Deposit(address sender, uint256 amount);
    event WithdrawByReceiver(address receiver);
    event WithdrawBySender(address sender);
    event OrderConfirmed(uint256 orderid);
    event OrderConfirmedBySender(address sender);
    event OrderConfirmedByReceiver(address receiver);
    event OrderCancelled(uint256 orderid);
    event OrderCancelledBySender(address sender);
    event OrderCancelledByReceiver(address receiver);
    event ConfirmationCancelled(uint256 orderid);
    event ConfirmationCancelledBySender(address sender);
    event ConfirmationCancelledByReceiver(address receiver);

    function deposit(address receiver, uint256 deadline) public payable {
        /// Increment the order sequence
        orderseq++;

        // New value with 1% fee
        uint256 amount = msg.value * 99 / 100;

        /// Store the order
        orders[orderseq] = Order({
            sender: msg.sender,
            receiver: receiver,
            amount: amount,
            deadline: deadline,
            status: OrderStatus.Pending,
            senderStatus: UserStatus.NOK,
            receiverStatus: UserStatus.NOK
        });

        emit Deposit(msg.sender, msg.value);
    }

    function confirmation(uint256 orderid) public {
        Order storage order = orders[orderid];

        if (order.sender == msg.sender) {
            order.senderStatus = UserStatus.OK;
            emit OrderConfirmedBySender(msg.sender);
        } else if (order.receiver == msg.sender) {
            order.receiverStatus = UserStatus.OK;
            emit OrderConfirmedByReceiver(msg.sender);
        } else {
            revert("You are not a participant of this order");
        }

        if (order.senderStatus == UserStatus.OK && order.receiverStatus == UserStatus.OK) {
            order.status = OrderStatus.Confirmed;
            emit OrderConfirmed(orderid);
        }
    }

    function cancelConfirmation(uint256 orderid) public {
        Order storage order = orders[orderid];

        if (order.sender == msg.sender) {
            order.senderStatus = UserStatus.NOK;
            emit ConfirmationCancelledBySender(msg.sender);
        } else if (order.receiver == msg.sender) {
            order.receiverStatus = UserStatus.NOK;
            emit ConfirmationCancelledByReceiver(msg.sender);
        } else {
            revert("You are not a participant of this order");
        }

        if (order.senderStatus == UserStatus.NOK || order.receiverStatus == UserStatus.NOK) {
            order.status = OrderStatus.Pending;
            emit ConfirmationCancelled(orderid);
        }
    }

    function cancelOrder(uint256 orderid) public {
        Order storage order = orders[orderid];

        if (order.sender == msg.sender) {
            order.senderStatus = UserStatus.CANCEL;
            emit OrderCancelledBySender(msg.sender);
        } else if (order.receiver == msg.sender) {
            order.receiverStatus = UserStatus.CANCEL;
            emit OrderCancelledByReceiver(msg.sender);
        } else {
            revert("You are not a participant of this order");
        }

        if (order.senderStatus == UserStatus.CANCEL && order.receiverStatus == UserStatus.CANCEL) {
            order.status = OrderStatus.Canceled;
            emit OrderCancelled(orderid);
        }
    }

    function withdraw(uint256 id) public payable {
        /// Get the order
        Order storage order = orders[id];

        // Check the receiver && sender
        require(
            order.receiver == msg.sender || order.sender == msg.sender,
            "You are not the sender or receiver"
        );

        // Check the status
        require(order.status != OrderStatus.Completed, "The order is not completed, you can not withdraw");
        require(order.status != OrderStatus.Pending, "The order is pending, it must be completed or canceled");

        /// Check the deadline
        require(order.deadline > block.timestamp, "Order is not completed");


        if (msg.sender == order.receiver && order.status == OrderStatus.Confirmed) {
            payable(order.receiver).transfer(order.amount);
            emit WithdrawByReceiver(order.receiver);
        } else if (msg.sender == order.sender && order.status == OrderStatus.Canceled) {
            payable(order.sender).transfer(order.amount);
            emit WithdrawBySender(order.sender);
        } else {
            revert("You are not the receiver");
        }

        /// Update the order status
        order.status = OrderStatus.Completed;


    }
}