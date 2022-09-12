// SPDX-License-Identifier: MIT

pragma solidity >=0.7.3;

struct OwnerInfo {
    string name;
    string id;
    string id_type;
    bool is_verified;
}

struct OwnershipInfo {
    OwnerInfo current_owner;
    OwnerInfo new_owner;
    CarInfo car;
}

struct CarInfo {
    string vin;
    string make;
    string model;
    string body;
    string seats;
    string doors;
    string model_detail;
    string import_history;
    string year;
    string km;
    string colour;
    string plate;
    string engine_size;
    string transmission;
    string fuel_type;
    string cylinders;
}

struct MoneyInfo {
    uint256 total_amount_cents;
    uint256 deposit_amount_cents;
    uint256 total_paid_amount_cents;
}

contract AutobaseBuy {
    OwnershipInfo public ownership;
    MoneyInfo public money;

    bool public is_deposit_paid = false;
    bool public is_fully_paid = false;
    bool public is_credit_applied = false;
    bool public is_credit_approved = false;
    bool public is_dealer_approved = false;
    bool public is_delivery_accepted = false;
    bool public is_ownership_released = false;
    bool public is_ownership_transferred = false;

    bool public is_contract_terminated = false;
    bool public is_contract_completed_successfully = false;

    string public start_date = "2022-09-16T20:19:32.221Z";
    string public terminate_date = "";
    string public acceptance_date = "";

    string public contract_version = "1.02";

    constructor(OwnershipInfo memory in_ownership, MoneyInfo memory in_money, string memory in_start_date)
    {
        ownership = in_ownership;
        money.total_amount_cents = in_money.total_amount_cents;
        money.deposit_amount_cents = in_money.deposit_amount_cents;
        start_date = in_start_date;
    }

    function pay(uint256 amount_paid_cents) public {
        money.total_paid_amount_cents += amount_paid_cents;

        if (money.total_paid_amount_cents >= money.deposit_amount_cents)
            is_deposit_paid = true;

        if (money.total_paid_amount_cents >= money.total_amount_cents)
            is_fully_paid = true;
    }

    function apply_credit() public {
        is_credit_applied = true;
    }

    function credit_result(bool is_approved) public {
        is_credit_approved = is_approved;
    }

    function dealer_approve() public {
        is_dealer_approved = true;
    }

    function accept_delivery(string memory accept_date) public {
        is_delivery_accepted = true;
        acceptance_date = accept_date;
    }

    function verify_registered_owner() public {
        ownership.current_owner.is_verified = true;
    }

    function verify_new_owner() public {
        ownership.new_owner.is_verified = true;
    }

    function release_ownership() public {
        is_ownership_released = true;
    }

    function transfer_ownership() public {
        is_ownership_transferred = true;
    }

    function cancel_contract(string memory contract_terminate_date) public {
        is_contract_terminated = true;
        terminate_date = contract_terminate_date;
    }
}