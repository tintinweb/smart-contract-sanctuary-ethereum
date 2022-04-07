// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// Interface for the FakeNFTMarketplace
interface IFakeNFTMarketplace {
    /// @dev nftPurchasePrice() reads the value of the public uint256 variable `nftPurchasePrice`
    function nftPurchasePrice() external view returns (uint256);

    /// @dev available() returns whether or not the given _tokenId has already been purchased
    /// @return Returns a boolean value - true if available, false if not
    function available(uint256 _tokenId) external view returns (bool);

    /// @dev ownerOf() returns the owner of a given _tokenId from the NFT marketplace
    /// @return returns the address of the owner
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @dev purchase() purchases an NFT from the FakeNFTMarketplace
    /// @param _tokenId - the fake NFT tokenID to purchase
    function purchase(uint256 _tokenId) external payable;

    /// @dev sell() pays the NFT owner `nftSalePrice` ETH and takes`tokenId` ownership back
    /// @param _tokenId the fake NFT token Id to sell back
    function sell(uint256 _tokenId) external;
}

// Minimal interface for CryptoDevs NFT containing the functions we care about
interface ICryptoDevsNFT {
    /// @dev balanceOf returns the number of NFTs owned by the given address
    /// @param owner - address to fetch number of NFTs for
    /// @return Returns the number of NFTs owned
    function balanceOf(address owner) external view returns (uint256);

    /// @dev tokenOfOwnerByIndex returns a tokenID at given index for owner
    /// @param owner - address to fetch the NFT TokenID for
    /// @param index - index of NFT in owned tokens array to fetch
    /// @return Returns the TokenID of the NFT
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /// @dev Returns the owner of the `tokenId` token.
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract CryptoDevsDAO is IERC721Receiver {
    // Interfaces to connect to the FakeNFTMarketplace and CryptoDevsNFT contracts
    IFakeNFTMarketplace nftMarketplace;
    ICryptoDevsNFT cryptoDevsNft;

    // Enums for Proposal Types and Vote Types
    enum ProposalType {
        BUY,
        SELL
    }
    enum VoteType {
        YAY,
        NAY
    }

    // Structs for Proposal and Member
    struct Proposal {
        // the tokenId to buy or sell from the marketplace
        uint256 nftTokenId;
        // the timestamp until which this proposal is open for voting
        uint256 deadline;
        // number of yes votes
        uint256 yayVotes;
        // number of no votes
        uint256 nayVotes;
        // has this proposal been executed
        bool executed;
        // is this proposal a buy or a sell?
        ProposalType proposalType;
        // mapping of members who have already voted
        mapping(address => bool) voters;
    }

    struct Member {
        uint256[] lockedUpNFTs;
        uint256 joinedAt;
    }

    // Mapping of proposal IDs to proposal structs
    mapping(uint256 => Proposal) public proposals;
    // mapping of members to locked up NFT token Ids
    mapping(address => Member) public members;
    // total number of proposals created so far
    uint256 numProposals;
    // total CryptoDevNFTs locked up by members
    uint256 totalVotingPower;

    // Constructor to setup interfaces, and accepts ETH deposit for initial treasury
    constructor(address cryptoDevsNftAddress, address marketplaceAddress)
        payable
    {
        cryptoDevsNft = ICryptoDevsNFT(cryptoDevsNftAddress);
        nftMarketplace = IFakeNFTMarketplace(marketplaceAddress);
    }

    // memberOnly modifier imposes membership to call functions
    modifier memberOnly() {
        require(members[msg.sender].lockedUpNFTs.length > 0, "NOT_A_MEMBER");
        _;
    }

    /// @dev createProposal - create a proposal within a DAO to buy/sell an NFT from Marketplace
    /// @param _forTokenId - token ID to buy/sell on the marketplace
    /// @param _proposalType - BUY or SELL?
    function createProposal(uint256 _forTokenId, ProposalType _proposalType)
        external
        memberOnly
        returns (uint256)
    {
        if (_proposalType == ProposalType.BUY) {
            require(nftMarketplace.available(_forTokenId), "NFT_NOT_FOR_SALE");
        } else {
            require(
                nftMarketplace.ownerOf(_forTokenId) == address(this),
                "NFT_NOT_OWNED"
            );
        }

        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _forTokenId;
        proposal.deadline = block.timestamp + 5 minutes;
        proposal.proposalType = _proposalType;

        numProposals++;

        return numProposals - 1;
    }

    /// @dev voteOnProposal - allows members to vote on active proposals
    /// @param _proposalId - ID of the proposal to vote on
    /// @param vote - YAY or NAY?
    function voteOnProposal(uint256 _proposalId, VoteType vote)
        external
        memberOnly
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.deadline > block.timestamp, "INACTIVE_PROPOSAL");
        require(proposal.voters[msg.sender] == false, "ALREADY_VOTED");

        proposal.voters[msg.sender] = true;
        uint256 votingPower = members[msg.sender].lockedUpNFTs.length;
        if (vote == VoteType.YAY) {
            proposal.yayVotes += votingPower;
        } else {
            proposal.nayVotes += votingPower;
        }
    }

    /// @dev executeProposal - allows any member to execute a proposal who's deadline has passed
    /// @param _proposalId - ID of proposal to execute
    function executeProposal(uint256 _proposalId) external memberOnly {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.deadline <= block.timestamp, "ACTIVE_PROPOSAL");
        require(proposal.executed == false, "ALREADY_EXECUTED");

        proposal.executed = true;
        if (proposal.yayVotes > proposal.nayVotes) {
            if (proposal.proposalType == ProposalType.BUY) {
                uint256 purchasePrice = nftMarketplace.nftPurchasePrice();
                require(
                    address(this).balance >= purchasePrice,
                    "NOT_ENOUGH_FUNDS"
                );
                nftMarketplace.purchase{value: purchasePrice}(
                    proposal.nftTokenId
                );
            } else {
                nftMarketplace.sell(proposal.nftTokenId);
            }
        }
    }

    /// @dev quit - allows members to quit the DAO, take their share of the profit and withdraw CryptoDevsNFTs back
    function quit() external memberOnly {
        Member storage member = members[msg.sender];
        require(
            block.timestamp - member.joinedAt > 10 minutes,
            "MIN_MEMBERSHIP_PERIOD"
        );

        uint256 share = address(this).balance / totalVotingPower;
        totalVotingPower -= member.lockedUpNFTs.length;
        payable(msg.sender).transfer(share);
        for (uint256 i = 0; i < member.lockedUpNFTs.length; i++) {
            cryptoDevsNft.safeTransferFrom(
                address(this),
                msg.sender,
                member.lockedUpNFTs[i],
                ""
            );
        }
        delete members[msg.sender];
    }

    /// @dev onERC721Received - look at {IERC721Receiver-onERC721Received}
    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes memory
    ) public override returns (bytes4) {
        require(cryptoDevsNft.ownerOf(_tokenId) == address(this), "MALICIOUS");
        Member storage member = members[_from];
        if (member.lockedUpNFTs.length == 0) {
            member.joinedAt = block.timestamp;
        }
        totalVotingPower++;
        members[_from].lockedUpNFTs.push(_tokenId);
        return this.onERC721Received.selector;
    }

    // The following two functions allow the contract to accept ETH deposits directly
    // from a wallet without calling a function
    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}