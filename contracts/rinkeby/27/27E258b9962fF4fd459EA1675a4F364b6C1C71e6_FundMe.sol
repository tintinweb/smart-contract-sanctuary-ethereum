// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    bool public updates;
    PurchaseInfo[] public purchases;

    struct PurchaseInfo {
        string typeOfNFT;
        uint256 amount;
        address purchaseAddress;
        uint16 orderNumber;
    }

    constructor() {
        owner = msg.sender;
    }

    function getOrderNumber() private view returns (uint16) {
        uint16 orderID = 1;
        for (uint256 i = 0; i < purchases.length; i++) {
            if (purchases[i].purchaseAddress == msg.sender) {
                orderID++;
            }
        }
        return orderID;
    }

    function fund() public payable allowFunding {
        //uint256 minimumUSD = 50 * 10 ** 18;  $50 example
        // require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value;
        PurchaseInfo memory pInfo = PurchaseInfo(
            "Base",
            msg.value,
            msg.sender,
            1
        );
        funders.push(msg.sender); //will add multiple of the same address NOT WANTED
        // what the ETH -> USD conversion rate
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
        //the _; means since it is after the code it executes before the code is called if it was reversed the reverse would happen.
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getFunders() public view returns (address[] memory) {
        return funders;
    }

    modifier allowFunding() {
        require(updates, "Funding has stopped");
        _;
    }

    function updateAllowed(bool allow) public onlyOwner {
        updates = allow;
    }
}