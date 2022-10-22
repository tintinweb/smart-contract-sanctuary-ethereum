// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract fund_me {

    address[] public funders;
    mapping (address => uint) public balances;

    address private immutable contract_owner;

    constructor() {
        contract_owner = msg.sender;
    }

    error fund_me__error();
    
    function fund() public payable {
        require(msg.value >= 1000, "The amount sent is too low...");

        if(balances[msg.sender] == 0) {
            funders.push(msg.sender);
            balances[msg.sender] = msg.value;
        } else {
            balances[msg.sender] += msg.value;
        }
    }

    function withdraw() public owner_only {
        for(uint i ; i < funders.length ; i++) {
            balances[funders[i]] = 0;
        }

        funders = new address[](0);

        (bool withdrawn,) = payable(msg.sender).call{value: address(this).balance}("");
        if(!withdrawn) revert();
    }

    modifier owner_only {
        //require(msg.sender == contract_owner);
        if(msg.sender != contract_owner) revert fund_me__error();
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}