// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);
}

struct Deposit {
    uint256 tokens;
    uint256 payout_timestamp;
    address receiver;
    address depositor;
    bool payout_approved;
    bool refund_approved;
}

contract MultiSig {

    IERC20 token;
    address owner;
    Deposit[] public deposits;

    constructor(address address_token) {
        token = IERC20(address_token);
        owner = msg.sender;
    }

    function deposit(address receiver, uint256 amount, uint256 payout_timestamp) public {
        token.transferFrom(msg.sender, address(this), amount);
        deposits.push(Deposit(amount, payout_timestamp, receiver, msg.sender, false, false));
    }

    function payout(uint256 deposit_index) public {
        Deposit memory this_deposit = deposits[deposit_index];
        require(this_deposit.tokens > 0, "This deposit has already been withdrawn");
        require(msg.sender == this_deposit.depositor, "You are not the depositor");
        deposits[deposit_index].tokens = 0;
        token.transfer(this_deposit.receiver, this_deposit.tokens);
    }

    function approve_payout(uint256 deposit_index) public {
        require(msg.sender == owner, "You are not the owner");
        deposits[deposit_index].payout_approved = true;
    }

    function approve_refund(uint256 deposit_index) public {
        require(msg.sender == owner, "You are not the owner");
        deposits[deposit_index].refund_approved = true;
    }

    function withdraw_payout(uint256 deposit_index) public {
        Deposit memory this_deposit = deposits[deposit_index];
        require(this_deposit.tokens > 0, "This deposit has already been withdrawn");
        require(this_deposit.payout_timestamp <= block.timestamp || msg.sender == this_deposit.receiver, "You are not the receiver and the time has not passed");
        require(this_deposit.payout_approved, "Payout not approved");
        deposits[deposit_index].tokens = 0;
        token.transfer(this_deposit.receiver, this_deposit.tokens);
    }

    function withdraw_refund(uint256 deposit_index) public {
        Deposit memory this_deposit = deposits[deposit_index];
        require(this_deposit.tokens > 0, "This deposit has already been withdrawn");
        require(msg.sender == this_deposit.depositor, "You are not the depositor");
        require(this_deposit.refund_approved, "Refund not approved");
        deposits[deposit_index].tokens = 0;
        token.transfer(this_deposit.depositor, this_deposit.tokens);
    }
}