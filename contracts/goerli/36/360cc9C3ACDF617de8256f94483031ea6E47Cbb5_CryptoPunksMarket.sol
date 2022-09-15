// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ICryptoPunksMarket } from "../interfaces/ICryptoPunksMarket.sol";

contract CryptoPunksMarket is ICryptoPunksMarket {
    // You can use this hash to verify the image file containing all the punks
    string public imageHash = "ac39af4793119ee46bbff351d8cb6b5f23da60222126add4268e261199a2921b";

    address owner;

    string public standard = "CryptoPunks";
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    bool public allPunksAssigned;
    uint256 public punksRemainingToAssign;

    //mapping (address => uint) public addressToPunkIndex;
    mapping(uint256 => address) public override punkIndexToAddress;

    /* This creates an array with all balances */
    mapping(address => uint256) public balanceOf;

    // A record of punks that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping(uint256 => Offer) public punksOfferedForSale;

    // A record of the highest punk bid
    mapping(uint256 => Bid) public punkBids;

    mapping(address => uint256) public pendingWithdrawals;

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(uint256 _totalSupply) {
        totalSupply = _totalSupply; // Update total supply
        for (uint256 i = 0; i < totalSupply; ++i) {
            punkIndexToAddress[i] = msg.sender;
        }
        balanceOf[msg.sender] = totalSupply; // Give the creator all initial tokens
        punksRemainingToAssign = 0;
        allPunksAssigned = true;
        owner = msg.sender;
        name = "CRYPTOPUNKS"; // Set the name for display purposes
        symbol = "C"; // Set the symbol for display purposes
        decimals = 0; // Amount of decimals for display purposes
    }

    // Transfer ownership of a punk to another user without requiring payment
    function transferPunk(address to, uint256 punkIndex) public override {
        if (!allPunksAssigned) revert();
        if (punkIndexToAddress[punkIndex] != msg.sender) revert();
        if (punkIndex >= totalSupply) revert();
        if (punksOfferedForSale[punkIndex].isForSale) {
            punkNoLongerForSale(punkIndex);
        }
        punkIndexToAddress[punkIndex] = to;
        balanceOf[msg.sender]--;
        balanceOf[to]++;
        emit Transfer(msg.sender, to, 1);
        emit PunkTransfer(msg.sender, to, punkIndex);
        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid storage bid = punkBids[punkIndex];
        if (bid.bidder == to) {
            // Kill bid and refund value
            pendingWithdrawals[to] += bid.value;
            punkBids[punkIndex] = Bid(false, punkIndex, address(0x0), 0);
        }
    }

    function punkNoLongerForSale(uint256 punkIndex) public override {
        if (!allPunksAssigned) revert();
        if (punkIndexToAddress[punkIndex] != msg.sender) revert();
        if (punkIndex >= totalSupply) revert();
        punksOfferedForSale[punkIndex] = Offer(false, punkIndex, msg.sender, 0, address(0x0));
        emit PunkNoLongerForSale(punkIndex);
    }

    function offerPunkForSaleToAddress(
        uint256 punkIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) public override {
        if (!allPunksAssigned) revert();
        if (punkIndexToAddress[punkIndex] != msg.sender) revert();
        if (punkIndex >= totalSupply) revert();
        punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, toAddress);
        emit PunkOffered(punkIndex, minSalePriceInWei, toAddress);
    }

    function buyPunk(uint256 punkIndex) public payable override {
        if (!allPunksAssigned) revert();
        Offer storage offer = punksOfferedForSale[punkIndex];
        if (punkIndex >= 5) revert();
        if (!offer.isForSale) revert(); // punk not actually for sale
        if (offer.onlySellTo != address(0x0) && offer.onlySellTo != msg.sender) revert(); // punk not supposed to be sold to this user
        if (msg.value < offer.minValue) revert(); // Didn't send enough ETH
        if (offer.seller != punkIndexToAddress[punkIndex]) revert(); // Seller no longer owner of punk

        address seller = offer.seller;

        punkIndexToAddress[punkIndex] = msg.sender;
        balanceOf[seller]--;
        balanceOf[msg.sender]++;
        emit Transfer(seller, msg.sender, 1);

        punkNoLongerForSale(punkIndex);
        pendingWithdrawals[seller] += msg.value;
        emit PunkBought(punkIndex, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid storage bid = punkBids[punkIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            punkBids[punkIndex] = Bid(false, punkIndex, address(0x0), 0);
        }
    }

    function withdraw() public override {
        if (!allPunksAssigned) revert();
        uint256 amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICryptoPunksMarket {
    struct Offer {
        bool isForSale;
        uint256 punkIndex;
        address seller;
        uint256 minValue;
        address onlySellTo;
    }

    struct Bid {
        bool hasBid;
        uint256 punkIndex;
        address bidder;
        uint256 value;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event PunkTransfer(address indexed from, address indexed to, uint256 punkIndex);
    event PunkOffered(uint256 indexed punkIndex, uint256 minValue, address indexed toAddress);
    event PunkBought(uint256 indexed punkIndex, uint256 value, address indexed fromAddress, address indexed toAddress);
    event PunkNoLongerForSale(uint256 indexed punkIndex);

    function transferPunk(address to, uint256 punkIndex) external;

    function punkNoLongerForSale(uint256 punkIndex) external;

    function offerPunkForSaleToAddress(
        uint256 punkIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) external;

    function buyPunk(uint256 punkIndex) external payable;

    function withdraw() external;

    function punkIndexToAddress(uint256 punkIndex) external view returns (address);
}