/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function balanceOf(address account) external view returns (uint256);
}

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
    address public owner;
    Deposit[] public deposits;
    IERC721 founders_cards;

    event DepositEvent(uint256 index);

    constructor(address address_token, address address_founders_cards) {
        token = IERC20(address_token);
        founders_cards = IERC721(address_founders_cards);
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
        uint256 fee_basispoints = 150;
        if(founders_cards.balanceOf(this_deposit.receiver) > 0) {
            fee_basispoints = 75;
        }
        uint256 fee = this_deposit.tokens * (fee_basispoints) / 1000;
        token.transfer(this_deposit.receiver, this_deposit.tokens - fee);
        token.transfer(owner, fee);
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

    function transfer_ownership(address new_owner) public {
        require(msg.sender == owner, "You are not the owner");
        owner = new_owner;
    }
}