/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

// SPDX-License-Identifier: GPL-3.0
// Block4Coffee

pragma solidity ^0.8.0;

contract Block4Coffee {

    mapping (address => uint) client_wallets;
    mapping (address => uint) client_debts;
    address[]                 coffee_providers;
    uint                      coffee_price;
    uint                      coffee_units;
    string[]                  coffee_refild_proofs;
    address                   owner = msg.sender;

    function sendMoney() external payable {
        // client has debt
        if (client_debts[msg.sender] > 0) {
            // obtain balance difference
            int balance_post_debt = int(msg.value - client_debts[msg.sender]);

            // if client still have debt
            if (balance_post_debt < 0) {
                balance_post_debt *= -1;
                // refresh debts
                client_debts[msg.sender] -= uint(balance_post_debt);
            }
            // client removed its debt
            else {
                client_debts[msg.sender] = 0;
                client_wallets[msg.sender] += uint(balance_post_debt);
            }
        }
        // client doesn't have debt
        else {
            client_wallets[msg.sender] += msg.value;
        }
    }

    function getMoneyBack() external {
        // check if balance null
        require(client_wallets[msg.sender] != 0);
        // retreive all money of sender
        payable(msg.sender).transfer(client_wallets[msg.sender]);
        // keep track on user's balance
        client_wallets[msg.sender] = 0;
    }

    function buyCoffee() external {
        require(coffee_price > 0);
        require(coffee_units > 0);

        // client have enough money to buy a coffee
        if (client_wallets[msg.sender] >= coffee_price) {
            client_wallets[msg.sender] -= coffee_price;
        }
        // client doesn't have enough money and could have debts
        else if (client_debts[msg.sender] + coffee_price <= (10 gwei)) {
            client_debts[msg.sender] += coffee_price;
        }
        // client can't pay
        else {
            revert();
        }

        coffee_units -= 1;
    }

    function addCoffeeProvider(address provider) external {
        // make sure that sender is owner
        require(msg.sender == owner);
        // add a provider
        // NOTE: checking is provider is already in list would
        //       be too greedy, and gas expensive
        coffee_providers.push(provider);
    }

    function fixCoffeePrice(uint price) external {
        require(price != 0);
        coffee_price = price;
    }

    function changeOwner(address new_owner) external {
        require(owner != new_owner);
        owner = new_owner;
    }

    function addCoffee(uint units, string memory proof) external {
        require(bytes(proof).length > 0);
        require(units > 0);
        require(coffee_price > 0);

        // compare sender to provider list
        bool is_provider = false;
        for (uint i = 0; i < coffee_providers.length; i++) {
            if (msg.sender == coffee_providers[i]) {
                is_provider = true;
                break;
            }
        }

        // check that caller is a provider
        require(is_provider == true);

        uint refild_price = units * coffee_price;
        // check that there is enough money in the contract
        require(address(this).balance >= refild_price);
        // pay the provider
        payable(msg.sender).transfer(refild_price);

        // store proof url       
        coffee_refild_proofs.push(proof);

        // update refild value
        coffee_units += units;
    }
}