/**
 *Submitted for verification at Etherscan.io on 2023-01-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct Listing {
    uint8 theType;
    address contractAddrNFT;
}

struct Bidding {
    address offer;
    uint256 unitPrice;
}

contract TradeImpl {
    mapping(uint64=>Listing) private listings;
    mapping(uint64=>Bidding) private topBiddings;

    function list(uint64 listingID, uint8 theType, address contractAddrNFT) public {
        listings[listingID] = Listing({theType: theType, contractAddrNFT: contractAddrNFT});
    }

    // function showContractAddr(uint64 listingID) public view returns (address) {
    //     return listings[listingID].contractAddrNFT;
    // }

    // function showType(uint64 listingID) public view returns (uint8) {
    //     return listings[listingID].theType;
    // }
}