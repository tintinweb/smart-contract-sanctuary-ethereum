/**
 *Submitted for verification at Etherscan.io on 2023-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC721 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract NFTListing {
    struct Listing {
        address owner;
        address buyer;
        address nftContract;
        uint256 tokenId;
        uint256 price;
        string tokenURI;
        bool active;
    }
    struct stakeNFT {
        bool active;
        address nftcontract;
        uint256 tokenId;
        uint256 stakingEndTime;
    }
    mapping(uint256 => Listing) public listings;
    mapping(uint256 => string) public tokenURIs; // Mapping to store token URIs
    mapping(address => mapping(uint256 => stakeNFT)) public stakedNFTs; // Mapping to store staked NFTs
    mapping(address => uint256) public stakecount;

    uint256 public nextListingId;
    address payable public owner;
    uint256 public TimePeriod = 1 days; // Staking time set to one day

    event NFTListed(
        uint256 indexed listingId,
        address indexed owner,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price,
        string tokenURI
    );

    event NFTUnlisted(uint256 indexed listingId);
    event NFTSold(uint256 indexed listingId, address indexed buyer);
    event NFTStaked(uint256 indexed tokenId, address indexed staker); // New event for NFT staking
    event NFTUnstaked(uint256 indexed tokenId, address indexed staker); // New event for NFT unstaking
    event Received(address indexed sender, uint256 amount);
    event EtherWithdrawn(address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only owner of the marketplace can change the period"
        );
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        owner = payable(newOwner);
    }

    function listingNFT(
        address nftContract,
        uint256[] memory tokenIds,
        uint256[] memory prices,
        string[] memory tokenURis
    ) external {
        IERC721 nft = IERC721(nftContract);
        require(
            tokenIds.length == prices.length &&
                tokenIds.length == tokenURis.length,
            "TokenIds, prices, and tokenURIs array length mismatch"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 price = prices[i];
            string memory uri = tokenURis[i];

            require(
                nft.ownerOf(tokenId) == msg.sender,
                "You must own the NFT to list it"
            );
            nft.transferFrom(msg.sender, address(this), tokenId);

            listings[nextListingId] = Listing({
                owner: msg.sender,
                buyer: address(0),
                nftContract: nftContract,
                tokenId: tokenId,
                price: price,
                tokenURI: uri, // Store the token URI
                active: true
            });
            tokenURIs[tokenId] = uri; // Store token URI in mapping
            emit NFTListed(
                nextListingId,
                msg.sender,
                nftContract,
                tokenId,
                price,
                uri // Emit the token URI in the event
            );
            nextListingId++;
        }
    }

    function unlistNFT(uint256[] memory listingIds) external {
        for (uint256 i = 0; i < listingIds.length; i++) {
            uint256 listingId = listingIds[i];
            Listing storage listing = listings[listingId];
            require(
                listing.owner == msg.sender,
                "You are not the owner of the listing"
            );

            IERC721 nft = IERC721(listing.nftContract);
            nft.transferFrom(address(this), msg.sender, listing.tokenId);

            listing.active = false; // Mark the listing as inactive

            emit NFTUnlisted(listingId);
        }
    }

    function buy(uint256[] memory listingIds) external payable {
        for (uint256 i = 0; i < listingIds.length; i++) {
            uint256 listingId = listingIds[i];
            Listing storage listing = listings[listingId];

            require(msg.value == listing.price, "Incorrect payment amount");

            address payable seller = payable(listing.owner);
            seller.transfer(msg.value);

            IERC721 nft = IERC721(listing.nftContract);
            nft.transferFrom(address(this), msg.sender, listing.tokenId);
            // Update the mapping
            listing.buyer = msg.sender;

            emit NFTSold(listingId, msg.sender);
        }
    }

    function stakedNFT(
        address nftContract,
        uint256[] memory tokenIds
    ) external {
        IERC721 nft = IERC721(nftContract);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            stakeNFT storage stake = stakedNFTs[msg.sender][tokenId];
            require(!stake.active, "NFT is already staked");

            nft.transferFrom(msg.sender, address(this), tokenId);

            uint256 stakingEndTime = block.timestamp + TimePeriod;

            stake.active = true;
            stake.nftcontract = nftContract;
            stake.tokenId = tokenId;
            stake.stakingEndTime = stakingEndTime;
            stakecount[msg.sender]++;
            emit NFTStaked(tokenId, msg.sender);
        }
    }

    function claimStakeNFT(uint256[] memory stakeid) external {
        for (uint256 i = 0; i < stakeid.length; i++) {
            uint256 tokenId = stakeid[i];
            stakeNFT storage stake = stakedNFTs[msg.sender][tokenId];
            require(stake.active, "NFT is not staked");

            require(
                stake.stakingEndTime <= block.timestamp,
                "The unlock period has not ended yet"
            );
            IERC721 nft = IERC721(stake.nftcontract);
            nft.transferFrom(address(this), msg.sender, tokenId);

            stake.active = false;

            emit NFTUnstaked(tokenId, msg.sender);
        }
    }

    function setTimePeriod(uint256 time) external onlyOwner {
        require(time > 0, "Invalid time period");
        TimePeriod = time;
    }

    function ownerOf(
        address nftContract,
        uint256 tokenId
    ) public view returns (address) {
        IERC721 nft = IERC721(nftContract);
        return nft.ownerOf(tokenId);
    }

    function getOwnedTokenIds(
        address wallet
    ) external view returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](nextListingId);
        uint256 count = 0;
        for (uint256 i = 0; i < nextListingId; i++) {
            Listing storage listing = listings[i];
            if (listing.owner == wallet) {
                tokenIds[count] = listing.tokenId;
                count++;
            }
        }
        assembly {
            mstore(tokenIds, count)
        }
        return tokenIds;
    }

    function withdrawEther(uint256 amount) external onlyOwner {
        require(
            amount <= address(this).balance,
            "Insufficient contract balance"
        );

        owner.transfer(amount);

        emit EtherWithdrawn(owner, amount);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}