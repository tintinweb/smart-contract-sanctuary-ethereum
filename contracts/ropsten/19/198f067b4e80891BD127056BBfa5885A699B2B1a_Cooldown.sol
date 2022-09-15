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
    event Withdraw(address sender);

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
        } else if (order.receiver == msg.sender) {
            order.receiverStatus = UserStatus.OK;
        } else {
            revert("You are not a participant of this order");
        }

        if (order.senderStatus == UserStatus.OK && order.receiverStatus == UserStatus.OK) {
            order.status = OrderStatus.Completed;
        }
    }

    function cancelConfirmation(uint256 orderid) public {
        Order storage order = orders[orderid];

        if (order.sender == msg.sender) {
            order.senderStatus = UserStatus.NOK;
        } else if (order.receiver == msg.sender) {
            order.receiverStatus = UserStatus.NOK;
        } else {
            revert("You are not a participant of this order");
        }

        if (order.senderStatus == UserStatus.NOK || order.receiverStatus == UserStatus.NOK) {
            order.status = OrderStatus.Pending;
        }
    }

    function cancelOrder(uint256 orderid) public {
        Order storage order = orders[orderid];

        if (order.sender == msg.sender) {
            order.senderStatus = UserStatus.CANCEL;
        } else if (order.receiver == msg.sender) {
            order.receiverStatus = UserStatus.CANCEL;
        } else {
            revert("You are not a participant of this order");
        }

        if (order.senderStatus == UserStatus.CANCEL && order.receiverStatus == UserStatus.CANCEL) {
            order.status = OrderStatus.Canceled;
        }
    }

    function withdraw(uint256 id) public {
        /// Get the order
        Order storage order = orders[id];

        // Check the receiver && sender
        require(
            order.receiver == msg.sender || order.sender == msg.sender,
            "You are not the sender or receiver"
        );

        // Check the status
        require(order.status == OrderStatus.Completed, "The order is not completed, you can not withdraw");
        require(order.status == OrderStatus.Pending, "The order is pending, it must be completed or canceled");

        /// Check the deadline
        require(order.deadline > block.timestamp, "Order is not completed");


        if (msg.sender == order.receiver && order.status == OrderStatus.Completed) {
            payable(order.receiver).transfer(order.amount);
            emit Withdraw(order.receiver);
        } else if (msg.sender == order.sender && order.status == OrderStatus.Canceled) {
            payable(order.sender).transfer(order.amount);
            emit Withdraw(order.sender);
        } else {
            revert("You are not the receiver");
        }

        /// Update the order status
        order.status = OrderStatus.Completed;

        emit Withdraw(msg.sender);
    }
}