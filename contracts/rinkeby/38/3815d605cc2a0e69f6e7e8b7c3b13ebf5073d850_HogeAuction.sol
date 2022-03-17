/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC2981 is IERC165 {
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Pausable is Context {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract HogeAuction is Pausable {
    address private _owner;
    address private _wallet;

    Auction[] public auctions;
    AuctionPayableStatus[] public auctionsPayableStatus;

    mapping(uint256 => Bid[]) public auctionBids;
    mapping(address => uint[]) public auctionOwner;

    struct Bid {
        address from;
        uint256 amount;
    }

    struct Auction {
        address owner;
        address nftAddress;
        uint256 tokenID;
        uint startPrice;
        uint bidStep;
        uint blockDeadline;
        bool active;
        bool finalized;
        bool isToken;
        address tokenAddress;
        address auctionAddress;
    }

    struct AuctionPayableStatus {
        bool paid;
        bool paidCommission;
        bool paidRoyalty;
        bool transfer;
    }

    event BidSuccess(address from, uint auctionID);
    event AuctionCreated(address owner, uint auctionID);
    event AuctionCanceled(address owner, address to, address nftAddress, uint tokenID, uint lastBid);
    event AuctionFinalized(address owner, address to, address nftAddress, uint tokenID, uint lastBid);

    constructor(address wallet_) {
        _wallet = wallet_;
        _owner = msg.sender;
    }

    function createAuction(
        address nftAddress,
        uint256 tokenID,
        uint startPrice,
        uint bidStep,
        uint blockDeadline,
        bool isToken,
        address tokenAddress,
        address auctionAddress
    ) public whenNotPaused() contractIsTokenOwner(nftAddress, tokenID, auctionAddress) {
        require(block.timestamp < blockDeadline, "createAuction: invalid blockDeadline");

        uint auctionId = auctions.length;

        Auction memory newAuction;
        newAuction.owner = msg.sender;
        newAuction.nftAddress = nftAddress;
        newAuction.blockDeadline = blockDeadline;
        newAuction.startPrice = startPrice;
        newAuction.bidStep = bidStep;
        newAuction.tokenID = tokenID;
        newAuction.active = true;
        newAuction.finalized = false;
        newAuction.isToken = isToken;
        newAuction.tokenAddress = tokenAddress;
        newAuction.auctionAddress = auctionAddress;

        AuctionPayableStatus memory newAuctionPayableStatus;
        newAuctionPayableStatus.paid = false;
        newAuctionPayableStatus.paidCommission = false;
        newAuctionPayableStatus.paidRoyalty = false;
        newAuctionPayableStatus.transfer = false;

        auctions.push(newAuction);
        auctionsPayableStatus.push(newAuctionPayableStatus);
        auctionOwner[msg.sender].push(auctionId);

        emit AuctionCreated(msg.sender, auctionId);
    }

    function bid(uint auctionID) public whenNotPaused() payable {
        require(auctions.length > auctionID, "bid: invalid auctionID");

        uint ethAmountSent = msg.value;
        Auction memory myAuction = auctions[auctionID];

        require(!myAuction.isToken, "bid: invalid token");
        require(myAuction.owner != msg.sender, "bid: invalid sender");
        require(block.timestamp < myAuction.blockDeadline, "bid: block deadline");

        uint bidsLength = auctionBids[auctionID].length;
        uint tempAmount = myAuction.startPrice;
        Bid memory lastBid;

        if (bidsLength > 0) {
            lastBid = auctionBids[auctionID][bidsLength - 1];
            tempAmount = lastBid.amount + myAuction.bidStep;
        }

        require(tempAmount <= ethAmountSent, "bid: invalid bid amount");
        if (bidsLength > 0) require(payable(lastBid.from).send(lastBid.amount), "bid: invalid transaction");

        Bid memory newBid;
        newBid.from = msg.sender;
        newBid.amount = ethAmountSent;
        auctionBids[auctionID].push(newBid);
        emit BidSuccess(msg.sender, auctionID);
    }

    function bidToken(uint auctionID, uint value) public whenNotPaused() {
        require(auctions.length > auctionID, "bidToken: invalid auctionID");
        uint ethAmountSent = value;
        Auction memory myAuction = auctions[auctionID];

        require(myAuction.isToken, "bidToken: invalid token");
        require(myAuction.owner != msg.sender, "bidToken: invalid sender");
        require(block.timestamp < myAuction.blockDeadline, "bidToken: block deadline");

        uint bidsLength = auctionBids[auctionID].length;
        uint tempAmount = myAuction.startPrice;
        Bid memory lastBid;

        if (bidsLength > 0) {
            lastBid = auctionBids[auctionID][bidsLength - 1];
            tempAmount = lastBid.amount + myAuction.bidStep;
        }

        require(tempAmount <= ethAmountSent, "bidToken: invalid bid amount");
        if (bidsLength > 0) require(IERC20(myAuction.tokenAddress).transfer(lastBid.from, lastBid.amount), "bidToken: invalid transaction");
        require(IERC20(myAuction.tokenAddress).transferFrom(msg.sender, myAuction.auctionAddress, value), "bidToken: invalid transaction");

        Bid memory newBid;
        newBid.from = msg.sender;
        newBid.amount = ethAmountSent;
        auctionBids[auctionID].push(newBid);
        emit BidSuccess(msg.sender, auctionID);
    }

    function finalizeAuction(uint auctionID) public whenNotPaused() {
        require(auctions.length > auctionID, "finalizeAuction: invalid auctionID");

        Auction memory myAuction = auctions[auctionID];
        AuctionPayableStatus memory myAuctionPayableStatus = auctionsPayableStatus[auctionID];
        uint bidsLength = auctionBids[auctionID].length;

        require(block.timestamp >= myAuction.blockDeadline, "finalizeAuction: block deadline");

        if (bidsLength == 0) {
            auctions[auctionID].active = false;
            auctions[auctionID].finalized = true;
            emit AuctionCanceled(myAuction.owner, myAuction.owner, myAuction.nftAddress, myAuction.tokenID, 0);
        } else {
            Bid memory lastBid = auctionBids[auctionID][bidsLength - 1];
            uint commission = lastBid.amount * 2 / 100;
            (address receiver, uint royaltyAmount) = IERC2981(myAuction.nftAddress).royaltyInfo(myAuction.tokenID, lastBid.amount);

            uint finaleAmount = lastBid.amount - (commission + royaltyAmount);

            // TOKEN TRANSFER
            if (!myAuctionPayableStatus.transfer) {
                if (IERC721(myAuction.nftAddress).ownerOf(myAuction.tokenID) != myAuction.owner) {
                    cancelAuction(auctionID);
                } else {
                    IERC721(myAuction.nftAddress).transferFrom(myAuction.owner, lastBid.from, myAuction.tokenID);
                    require(IERC721(myAuction.nftAddress).ownerOf(myAuction.tokenID) == lastBid.from, "finalizeAuction: invalid transfer transaction");
                }
            }
            auctionsPayableStatus[auctionID].transfer = true;

            // COMMISSION
            if (!myAuctionPayableStatus.paidCommission) {
                if (myAuction.isToken) require(IERC20(myAuction.tokenAddress).transfer(_wallet, commission), "finalizeAuction: invalid commission transaction");
                else require(payable(_wallet).send(commission), "finalizeAuction: invalid commission transaction");
            }
            auctionsPayableStatus[auctionID].paidCommission = true;

            // ROYALTY
            if (!myAuctionPayableStatus.paidRoyalty) {
                if (myAuction.isToken) require(IERC20(myAuction.tokenAddress).transfer(receiver, royaltyAmount), "finalizeAuction: invalid royalty transaction");
                else require(payable(receiver).send(royaltyAmount), "finalizeAuction: invalid royalty transaction");
            }
            auctionsPayableStatus[auctionID].paidRoyalty = true;

            // TOKEN SALE
            if (!myAuctionPayableStatus.paid) {
                if (myAuction.isToken) require(IERC20(myAuction.tokenAddress).transfer(myAuction.owner, finaleAmount), "finalizeAuction: invalid sale transaction");
                else require(payable(myAuction.owner).send(finaleAmount), "finalizeAuction: invalid sale transaction");
            }
            auctionsPayableStatus[auctionID].paid = true;

            auctions[auctionID].active = false;
            auctions[auctionID].finalized = true;
            emit AuctionFinalized(myAuction.owner, lastBid.from, myAuction.nftAddress, myAuction.tokenID, lastBid.amount);
        }
    }

    function cancelAuction(uint auctionID) public isOwner(auctionID) {
        Auction memory myAuction = auctions[auctionID];
        uint bidsLength = auctionBids[auctionID].length;

        if (bidsLength > 0) {
            Bid memory lastBid = auctionBids[auctionID][bidsLength - 1];
            if (myAuction.isToken) require(IERC20(myAuction.tokenAddress).transfer(lastBid.from, lastBid.amount), "cancelAuction: invalid transfer transaction");
            else require(payable(lastBid.from).send(lastBid.amount), "cancelAuction: invalid send transaction");
        }

        auctions[auctionID].active = false;
        emit AuctionCanceled(msg.sender, msg.sender, myAuction.nftAddress, myAuction.tokenID, 0);
    }

    function changeWallet(address wallet_) public whenNotPaused() isContractOwner() {
        _wallet = wallet_;
    }

    function followBack() public whenPaused() isContractOwner() {
        for (uint auctionID = 0; auctionID < auctions.length; auctionID++) {
            if (auctions[auctionID].active) {
                cancelAuction(auctionID);
            }
        }
    }

    function pause() public isContractOwner() whenNotPaused() {
        _pause();
    }

    function unpause() public isContractOwner() whenPaused() {
        _unpause();
    }

    function getWallet() public view returns (address) {
        return _wallet;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    function isFinalizedAuction(uint auctionID) public view returns (bool) {
        require(auctions.length > auctionID, "HogeAuction: invalid auctionID");
        Auction memory myAuction = auctions[auctionID];
        return myAuction.finalized;
    }

    function isActiveAuction(uint auctionID) public view returns (bool) {
        require(auctions.length > auctionID, "HogeAuction: invalid auctionID");
        Auction memory myAuction = auctions[auctionID];
        return myAuction.active;
    }

    modifier isContractOwner() {
        require(_owner == msg.sender, "HogeAuction: not owner");
        _;
    }

    modifier isOwner(uint auctionID) {
        require(auctions.length > auctionID, "HogeAuction: invalid auctionID");
        require(auctions[auctionID].owner == msg.sender || _owner == msg.sender, "HogeAuction: not owner");
        _;
    }

    modifier contractIsTokenOwner(address nftAddress, uint256 tokenID, address auctionAddress) {
        address owner = IERC721(nftAddress).ownerOf(tokenID);
        require(owner == msg.sender && (IERC721(nftAddress).getApproved(tokenID) == auctionAddress || IERC721(nftAddress).isApprovedForAll(owner, auctionAddress)), "HogeAuction: not approved");
        _;
    }
}