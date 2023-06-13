/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClassicCar {

    struct Document {
        string computedHash;
        string docType;
    }

    struct AuctionData {
        bool isListed;
        uint256 reservePrice;
        address highestBidder;
        uint256 highestBid;
        uint256 auctionEndTime;
    }
    
    address public controller;
    address[] public admins;
    string public vin;
    Document[] documents;
    AuctionData[] auctionData;

    event AdminAdded(address admin);
    event AdminRemoved(address admin);

    modifier onlyController() {
        require(msg.sender == controller, "Only the controller address can call this function.");
        _;
    }

    modifier onlyAdmin() {
        require(
            isAdmin(msg.sender) || msg.sender == controller,
            "Only admins can call this function."
        );
        _;
    }

    constructor(address _controller, string memory _vin) {
        controller = _controller;
        admins.push(_controller);
        vin = _vin;
    }

    function addDocument(
        string memory computedHash,
        string memory docType
    ) public onlyAdmin {
        Document memory document = Document(
            computedHash,
            docType
        );
        documents.push(document);
    }

    function addAuctionData(
        bool isListed,
        uint256 reservePrice,
        uint256 auctionEndTime
    ) public onlyAdmin {
        AuctionData memory newAuctionData = AuctionData(
            isListed,
            reservePrice,
            address(0),
            0,
            auctionEndTime
        );
        auctionData.push(newAuctionData);
    }

    function isAdmin(address account) public view returns (bool) {
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == account) {
                return true;
            }
        }
        return false;
    }

    function addAdmin(address admin) public onlyController {
        require(admin != address(0), "Invalid admin address.");
        admins.push(admin);

        emit AdminAdded(admin);
    }

    function removeAdmin(address admin) public onlyController {
        require(admin != address(0), "Invalid admin address.");
        require(isAdmin(admin), "Address is not an admin.");

        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == admin) {
                admins[i] = admins[admins.length - 1];
                admins.pop();
                break;
            }
        }

        emit AdminRemoved(admin);
    }

    function getAllAdmins() public view returns (address[] memory) {
        return admins;
    }

    function getAuctionData() public view returns (AuctionData[] memory) {
        return auctionData;
    }

    function getDocuments() public view returns (Document[] memory) {
        return documents;
    }
}