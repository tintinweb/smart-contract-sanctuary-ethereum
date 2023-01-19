// SPDX-License-Identifier: -

pragma solidity ^0.8.4;

import "../interfaces/IPunks.sol";

contract TestnetPunks is IPunks {
    string public standard = "CryptoPunks";
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    uint256 public counter = 0;

    struct Offer {
        bool isForSale;
        uint256 punkIndex;
        address seller;
        uint256 minValue; // in ether
        address onlySellTo; // specify to sell only to a specific person
    }

    // A record of punks that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping(uint256 => Offer) public punksOfferedForSale;

    //mapping (address => uint) public addressToPunkIndex;
    mapping(uint256 => address) public override punkIndexToAddress;

    /* This creates an array with all balances */
    mapping(address => uint256) public override balanceOf;

    mapping(address => uint256) public pendingWithdrawals;

    event Assign(address indexed to, uint256 punkIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event PunkTransfer(address indexed from, address indexed to, uint256 punkIndex);
    event PunkOffered(uint256 indexed punkIndex, uint256 minValue, address indexed toAddress);
    event PunkBought(uint256 indexed punkIndex, uint256 value, address indexed fromAddress, address indexed toAddress);
    event PunkNoLongerForSale(uint256 indexed punkIndex);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor() payable {
        totalSupply = 10000; // Update total supply
        name = "TESTNETPUNKS"; // Set the name for display purposes
        symbol = "TC"; // Set the symbol for display purposes
        decimals = 0; // Amount of decimals for display purposes
    }

    function mintPunk(address to) public {
        uint256 punkIndex = counter;
        punkIndexToAddress[punkIndex] = to;
        balanceOf[to]++;
        counter++;
        emit Assign(to, punkIndex);
    }

    // Transfer ownership of a punk to another user without requiring payment
    function transferPunk(address to, uint256 punkIndex) public override {
        require(punkIndexToAddress[punkIndex] == msg.sender, "sender not owner");
        require(punkIndex < 10000, "index >= 10000");
        punkIndexToAddress[punkIndex] = to;
        balanceOf[msg.sender]--;
        balanceOf[to]++;
        emit Transfer(msg.sender, to, 1);
        emit PunkTransfer(msg.sender, to, punkIndex);
    }

    function offerPunkForSaleToAddress(
        uint256 punkIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) external override {
        require(punkIndexToAddress[punkIndex] == msg.sender, "sender not owner");
        require(punkIndex < 10000, "index >= 10000");
        punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, toAddress);
        emit PunkOffered(punkIndex, minSalePriceInWei, toAddress);
    }

    function buyPunk(uint256 punkIndex) external payable override {
        Offer memory offer = punksOfferedForSale[punkIndex];
        require(punkIndex < 10000, "index >= 10000");
        require(offer.isForSale, "punk not for sale");
        require(offer.onlySellTo == address(0) || offer.onlySellTo == msg.sender, "shouldnt be sold to this user");
        require(msg.value >= offer.minValue, "not enough ETH sent");
        require(punkIndexToAddress[punkIndex] == offer.seller, "seller not owner");

        address seller = offer.seller;

        punkIndexToAddress[punkIndex] = msg.sender;
        balanceOf[seller]--;
        balanceOf[msg.sender]++;
        emit Transfer(seller, msg.sender, 1);

        punkNoLongerForSale(punkIndex);
        emit PunkBought(punkIndex, msg.value, seller, msg.sender);
    }

    function punkNoLongerForSale(uint256 punkIndex) public {
        require(punkIndexToAddress[punkIndex] == msg.sender, "sender not owner");
        require(punkIndex < 10000, "index >= 10000");
        punksOfferedForSale[punkIndex] = Offer(false, punkIndex, msg.sender, 0, address(0));
        emit PunkNoLongerForSale(punkIndex);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IPunks {
    function balanceOf(address owner) external view returns (uint256);

    function punkIndexToAddress(uint256 punkIndex) external view returns (address);

    function transferPunk(address to, uint256 punkIndex) external;

    function offerPunkForSaleToAddress(
        uint256 punkIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) external;

    function buyPunk(uint256 punkIndex) external payable;
}