// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);
}
struct Deposit {
    uint256 tokens;
    uint256 payout_timestamp;
    address receiver;
    address depositor;
}

contract MultiSig {
    IERC20 token;
    address owner;
    Deposit[] public deposits;

    event DepositEvent(uint256 index);

    constructor(address address_token) {
        token = IERC20(address_token);
        owner = msg.sender;
    }

    function deposit(
        address receiver,
        uint256 amount,
        uint256 payout_timestamp
    ) public {
        token.transferFrom(msg.sender, address(this), amount);
        deposits.push(Deposit(amount, payout_timestamp, receiver, msg.sender));
        emit DepositEvent(deposits.length - 1);
    }

    function payout(uint256 deposit_index) public {
        Deposit memory this_deposit = deposits[deposit_index];
        require(
            this_deposit.tokens > 0,
            "This deposit has already been withdrawn"
        );
        require(
            msg.sender == this_deposit.depositor || msg.sender == owner,
            "You are neither the depositor nor the owner"
        );
        deposits[deposit_index].tokens = 0;
        token.transfer(this_deposit.receiver, this_deposit.tokens);
    }

    function refund(uint256 deposit_index) public {
        Deposit memory this_deposit = deposits[deposit_index];
        require(
            this_deposit.tokens > 0,
            "This deposit has already been withdrawn"
        );
        require(
            msg.sender == this_deposit.receiver || msg.sender == owner,
            "You are neither the owner nor the receiver"
        );
        deposits[deposit_index].tokens = 0;
        token.transfer(this_deposit.depositor, this_deposit.tokens);
    }
}