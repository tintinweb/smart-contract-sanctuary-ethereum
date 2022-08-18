/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract ContentMutualSubscription {
    address private immutable owner;
    address private immutable author;
    address private immutable publisher;
    address private immutable USDC_CONTRACT;

    uint public max;
    uint public withdrawn;

    event SetMax(uint max);
    event PayToAuthor(uint amount);

    constructor(address _author, address _publisher, address _usdc_contract) {
        owner = msg.sender;
        author = _author;
        publisher = _publisher;

        USDC_CONTRACT = _usdc_contract;

        max = 0;
        withdrawn = 0;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getAuthor() public view returns (address) {
        return author;
    }

    function getPublisher() public view returns (address) {
        return publisher;
    }

    modifier onlyAuthor() {
        require(msg.sender == author, "Not the author.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner.");
        _;
    }

    receive() external payable {

    }

    function payToAuthor() public onlyAuthor {
        uint amount = max - withdrawn;
        require(amount > 0, "Nothing to withdraw.");
        require(IERC20(USDC_CONTRACT).transfer(msg.sender, amount), "Transaction is not successful.");
        withdrawn = max;
        emit PayToAuthor(amount);
    }

    function setMax(uint _max) public onlyOwner {
        require(_max > max, "Amount should be more than current limit.");
        max = _max;
        emit SetMax(max);
    }
}