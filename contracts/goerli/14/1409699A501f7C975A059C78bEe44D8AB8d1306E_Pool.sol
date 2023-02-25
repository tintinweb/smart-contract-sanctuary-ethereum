/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Pool {
    struct Entry {
        uint256 amount;
        uint256 timeStamp;
        bool isActive;
    }

    address owner;

    mapping(address => Entry[]) lenders;
    mapping(address => Entry[]) borrowers;

    uint256 constant lend_interest_rate = 2;
    uint256 constant borrow_interest_rate = 3;

    constructor() {
        owner = msg.sender;
    }

    event LendLog(address indexed sender, uint256 amount, uint256 timestamp);
    event BorrowLog(address indexed sender, uint256 amount, uint256 timestamp);

    receive() external payable {
        require(msg.sender == owner);
    }

    fallback() external payable {}

    function computeLenderBalance(address lender, uint256 index, uint256 timestamp)
        internal
        view
        returns (uint256)
    {
        Entry memory entry = lenders[lender][index];
        uint256 amount = entry.amount;
        uint256 time_periods_hrs = timestamp / 1000 / 3600 - entry.timeStamp / 1000 / 3600;

        // Return amount to be withdrawn P + I
        return
            amount +
            ((amount * time_periods_hrs) *
                lend_interest_rate) /
            10000;
    }

    function getLenderEntries() public view returns (Entry[] memory) {
        uint256[] memory arr = new uint256[](lenders[msg.sender].length);

        // for (uint256 i = 0; i < lenders[msg.sender].length; i++)
        //    arr[i] = lenders[msg.sender][i].amount;

        return lenders[msg.sender];
    }

    function getLenderBalance(uint256 index, uint256 timestamp) public view returns (uint256) {
        // Return amount to be withdrawn P + I
        return computeLenderBalance(msg.sender, index, timestamp);
    }

    function lend(uint256 timestamp) public payable {
        lenders[msg.sender].push(Entry(msg.value, timestamp, true));
        emit LendLog(msg.sender, msg.value, timestamp);
    }

    function withdraw(uint256 index, uint256 timestamp) public payable {
        require(index <= lenders[msg.sender].length);
        require(lenders[msg.sender][index].isActive == true);
        uint256 amount = computeLenderBalance(msg.sender, index, timestamp);

        lenders[msg.sender][index].isActive = false;

        // for(uint i = index; i < lenders[msg.sender].length - 1; i++)
        //     lenders[msg.sender][i] = lenders[msg.sender][i + 1];
        // TODO: Properly delete array element

        // lenders[msg.sender].pop();
        payable(msg.sender).transfer(amount);
    }

    function computeBorrowerBalance(address borrower, uint256 index, uint256 timestamp)
        internal
        view
        returns (uint256)
    {
        Entry memory entry = borrowers[borrower][index];
        uint256 amount = entry.amount;
        uint256 time_periods_hrs = timestamp / 1000 / 3600 - entry.timeStamp / 1000 / 3600;

        // Return amount to be paid back P + I
        return
            amount +
            ((amount * time_periods_hrs) *
                borrow_interest_rate) /
            10000;
    }

    function getBorrowerEntries() public view returns (Entry[] memory) {
        uint256[] memory arr = new uint256[](borrowers[msg.sender].length);

        // for (uint256 i = 0; i < borrowers[msg.sender].length; i++)
        //    arr[i] = borrowers[msg.sender][i].amount;

        return borrowers[msg.sender];
    }

    function getBorrowerBalance(uint256 index, uint256 timestamp) public view returns (uint256) {
        // Return amount to be paid back P + I
        return computeBorrowerBalance(msg.sender, index, timestamp);
    }

    function borrow(uint256 amount, uint256 timestamp) public payable {
        require(amount <= address(this).balance);
        borrowers[msg.sender].push(Entry(amount, timestamp, true));
        payable(msg.sender).transfer(amount);
        emit BorrowLog(msg.sender, amount, timestamp);
    }

    function payback(uint256 index, uint256 timestamp) public payable {
        require(index <= borrowers[msg.sender].length);
        require(borrowers[msg.sender][index].isActive == true);
        uint256 amount = computeBorrowerBalance(msg.sender, index, timestamp);
        require(msg.value == amount);

        borrowers[msg.sender][index].isActive = false;

        // TODO: Properly delete array element
        // for(uint i = index; i < borrowers[msg.sender].length - 1; i++)
        //    borrowers[msg.sender][i] = borrowers[msg.sender][i + 1];

        // borrowers[msg.sender].pop();
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}