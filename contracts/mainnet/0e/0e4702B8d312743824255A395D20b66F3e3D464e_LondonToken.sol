// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC2981PerTokenRoyalties.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

/// @custom:security-contact [email protected]
contract LondonToken is
    ERC721,
    Ownable,
    ERC2981PerTokenRoyalties,
    DefaultOperatorFilterer
{
    constructor(
        string memory uri_,
        address minter_,
        address gatewayManager_
    ) ERC721("LondonToken_0.3", "VERSE", uri_) {
        mintingManager = minter_;
        gatewayManager = gatewayManager_;
    }

    /**
     * @dev OS Operator filtering
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev OS Operator filtering
     */
    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /**
     * @dev OS Operator filtering
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev OS Operator filtering
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev OS Operator filtering
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    address public mintingManager;

    address public gatewayManager;

    /**
     * @dev Creates a token with `id`, and assigns them to `to`.
     * In addition it sets the royalties for `royaltyRecipient` of the value `royaltyValue`.
     * Method emits two transfer events.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function mintWithCreator(
        address creator,
        address to,
        uint256 tokenId,
        string memory cid,
        address royaltyRecipient,
        uint256 royaltyValue
    ) public onlyMinter {
        require(to != address(0), "mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;
        _cids[tokenId] = cid;

        if (royaltyValue > 0) {
            _setTokenRoyalty(tokenId, royaltyRecipient, royaltyValue);
        }

        emit Transfer(address(0), creator, tokenId);
        emit Transfer(creator, to, tokenId);
    }

    /**
     * @dev Creates a token with `id`, and assigns them to `to`.
     * In addition it sets the royalties for `royaltyRecipient` of the value `royaltyValue`.
     * Method emits two transfer events.
     *
     * Emits a {Transfer} events for intermediate artist.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function batchMintWithCreator(
        address[] memory to,
        address creator,
        uint256[] memory tokenIds,
        string[] memory tokenCids,
        address royaltyRecipient,
        uint256 royaltyValue
    ) public onlyMinter {
        require(
            tokenIds.length == to.length && tokenIds.length == tokenCids.length,
            "Arrays length mismatch"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            mintWithCreator(
                creator,
                to[i],
                tokenIds[i],
                tokenCids[i],
                royaltyRecipient,
                royaltyValue
            );
        }
    }

    modifier onlyMinter() {
        require(msg.sender == mintingManager);
        _;
    }

    modifier onlyGatewayManager() {
        require(msg.sender == gatewayManager);
        _;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Checks for supported interface.
     *
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Sets royalties for `tokenId` and `tokenRecipient` with royalty value `royaltyValue`.
     *
     */
    function setRoyalties(
        uint256 tokenId,
        address royaltyRecipient,
        uint256 royaltyValue
    ) public onlyOwner {
        _setTokenRoyalty(tokenId, royaltyRecipient, royaltyValue);
    }

    /**
     * @dev Sets new minter for the contract.
     *
     */
    function setMintingManager(address minter_) public onlyOwner {
        mintingManager = minter_;
    }

    /**
     * @dev Sets new gateway manager for the contract.
     *
     */
    function setGatewayManager(address gatewayManager_) public onlyOwner {
        gatewayManager = gatewayManager_;
    }

    /**
     * @dev Sets base URI for metadata.
     *
     */
    function setURI(string memory newuri) public onlyGatewayManager {
        _setURI(newuri);
    }

    /**
     * @dev Sets IPFS cid metadata hash for token id `tokenId`.
     *
     */
    function setCID(uint256 tokenId, string memory cid)
        public
        onlyGatewayManager
    {
        _cids[tokenId] = cid;
    }

    /**
     * @dev Sets IPFS cid metadata hash for token id `tokenId`.
     *
     */
    function setCIDs(uint256[] memory tokenIds, string[] memory cids_)
        public
        onlyGatewayManager
    {
        require(
            tokenIds.length == cids_.length,
            "ERC1155: Arrays length mismatch"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _cids[tokenIds[i]] = cids_[i];
        }
    }
}