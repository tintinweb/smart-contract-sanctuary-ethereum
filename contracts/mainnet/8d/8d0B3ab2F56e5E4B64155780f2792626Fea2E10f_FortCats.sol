// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface Realms {
    function ownerOf(uint256 tokenId) external returns (address);
}

interface MoonCats {
    function ownerOf(uint256 tokenId) external returns (address);
}

interface MistCoin {
    function balanceOf(address account) external returns (uint256);
    function allowance(address owner, address spender) external returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract FortCats {

    event FortOffered(uint256 indexed fortID, uint256 indexed price);
    event FortRented(uint256 indexed catID, uint256 indexed fortID);
    event FortCleared(uint256 indexed fortID);

    Realms realms = Realms(0x8479277AaCFF4663Aa4241085a7E27934A0b0840);
    MoonCats moonCats = MoonCats(0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69);
    MistCoin mistCoin = MistCoin(0x7Fd4d7737597E7b4ee22AcbF8D94362343ae0a79);

    uint256 constant DURATION = 220000;

    struct Fort {
        uint256 price;
        uint256 renter;
        uint256 checkout;
    }

    mapping (uint256 => Fort) public forts;
    mapping (uint256 => uint256) public fortRented;

    constructor() {}

    function isFortClear(uint256 fortID) public view returns (bool) {
        return (forts[fortID].price == 0 && forts[fortID].renter == 0 && forts[fortID].checkout == 0);
    }

    function offerFort(uint256 fortID, uint256 price) external {
        require (msg.sender == realms.ownerOf(fortID), "You do not own this fortress");
        require (price > 0, "You cannot offer the fortress for free");
        require (isFortClear(fortID));

        forts[fortID].price = price;

        emit FortOffered(fortID, price);
    }

    function rentFort(uint256 catID, uint256 fortID) external {
        require(catID != 0, "Cat number zero is not allowed to rent");
        require(msg.sender == moonCats.ownerOf(catID), "You do not own this cat");
        require(fortRented[catID] == 0, "This cat is already renting a fortress");
        require(forts[fortID].price != 0, "This fortress is not available to rent");
        require(mistCoin.balanceOf(msg.sender) >= forts[fortID].price, "You do not have enough MistCoin");
        require(mistCoin.allowance(msg.sender, address(this)) >= forts[fortID].price,
            "You must increase the MistCoin allowance for this contract to the price of rent");

        mistCoin.transferFrom(msg.sender, realms.ownerOf(fortID), forts[fortID].price);
        fortRented[catID] = fortID;
        forts[fortID].price = 0;
        forts[fortID].renter = catID;
        forts[fortID].checkout = block.number + DURATION;

        emit FortRented(catID, fortID);
    }

    function clearFort(uint256 fortID) external {
        require(block.number > forts[fortID].checkout && msg.sender == realms.ownerOf(fortID) ||
                block.number <= forts[fortID].checkout && msg.sender == moonCats.ownerOf(forts[fortID].renter),
                    "You do not have permission to clear the fortress");

        fortRented[forts[fortID].renter] = 0;
        forts[fortID].price = 0;
        forts[fortID].renter = 0;
        forts[fortID].checkout = 0;

        emit FortCleared(fortID);
    }
}