/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract Proxy {
    address public owner;
    address public mpAddress;
    uint balance;

    constructor(address approver) {
        owner = msg.sender;
        mpAddress = approver;
    }

    function deposit() public payable {
        require(owner == msg.sender, "only sender can deposit!");
        balance += msg.value;
    }

    function transferTo(address receiver, uint amount) public {
        require(msg.sender == owner || msg.sender == mpAddress, "widthdrow can deposit only owner or mpAddress");
        require(balance >= amount, "insufficient balance");
        payable(receiver).transfer(amount);
        balance -= amount;
    }
}

contract ERC721 {
    mapping (uint => address) tokens;

    function mint(address tokenOwner, uint tokenId) public {
        tokens[tokenId] = tokenOwner;
    }

    function transferFrom(address from, address to, uint tokenId) public {
        require(tokens[tokenId] == from, "insufficient balance");

        tokens[tokenId] = to;
    }
}

contract MP {

    ERC721 public tokensAddress;
    address public feeAddress;

    constructor(address tokenAddr, address feeAddr) {
        tokensAddress = ERC721(tokenAddr);
        feeAddress = feeAddr;
    }

    function trade(address buyer, address seller, uint tokenId, uint price, uint feeAmount) public {
        Proxy(buyer).transferTo(seller, price);
        tokensAddress.transferFrom(seller, buyer, tokenId);
        Proxy(seller).transferTo(feeAddress, feeAmount);
    }
}