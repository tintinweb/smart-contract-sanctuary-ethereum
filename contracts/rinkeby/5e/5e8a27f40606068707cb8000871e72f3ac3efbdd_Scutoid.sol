/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

contract Scutoid {

    struct Book { 
        string _author;
        string _ipfsUrl;
        uint amount;
    }

    mapping (address => Book[]) public walletBooks;
    mapping (address => bool) public isHolder;
    uint public holderNumber = 0;

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function transfer(address payable _to) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, ) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    function mint(address payable _to, uint amount, string memory author, string memory url) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        Book memory book = Book(author, url, amount);
        walletBooks[msg.sender].push(book);
        if (!isHolder[msg.sender]) {
            isHolder[msg.sender] = true;
            holderNumber++;
        }
        (bool sent, ) = _to.call{value: msg.value*amount}("");
        require(sent, "Failed to send Ether");
    }

    function getWalletLength() view public returns (uint) {
        return holderNumber;
    }

    function getWalletBook(address _wallet) view public returns (Book[] memory) {
        return walletBooks[_wallet];
    }
}