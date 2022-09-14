/**
 *Submitted for verification at Etherscan.io on 2022-09-13
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract PurchaseAgreementLite {

    uint public value;
    address payable public owner;
    address payable public buyer;

    enum State { Created, Locked, Inactive }
    State public state;

    constructor() payable {
        owner = payable(msg.sender);
    }

    /// The function cannot be called in current state
    error InvalidState();

    /// Only buyer can call this function
    error OnlyBuyer();

    /// Only seller can call this function
    error OnlyWallet();

    modifier inState(State _state) {
        if (state != _state) {
            revert InvalidState();
        }
        _;
    }

    modifier onlyBuyer() {
        if (msg.sender != buyer) {
            revert OnlyBuyer();
        }
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyWallet();
        }
        _;
    }

    function confirmPurchase() external inState(State.Created) payable {
        value = msg.value;
        buyer = payable(msg.sender);
        state = State.Locked;
    }

    function paySeller() external onlyOwner inState(State.Locked) {
        state = State.Created;
        owner.transfer(value);
        buyer = payable(address(0));
        value = 0;
    }

    function abort() external onlyOwner inState(State.Locked) {
        state = State.Created;
        buyer.transfer(value);
        buyer = payable(address(0));
        value = 0;
    }
}