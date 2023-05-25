// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC2981PerTokenRoyalties.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

/// @custom:security-contact [email protected]
contract LondonTokenBase is
    ERC721,
    Ownable,
    ERC2981PerTokenRoyalties,
    DefaultOperatorFilterer
{
    constructor() ERC721("", "VERSE", "") {}

    function initialize(
        string memory uri_,
        address minter_,
        address gatewayManager_,
        string memory contractName_,
        uint256 royaltyValue_
    ) public {
        require(bytes(_name).length == 0, "Already initialized");
        _name = contractName_;
        _baseUri = uri_;
        mintingManager = minter_;
        gatewayManager = gatewayManager_;
        _setTokenRoyalty(msg.sender, royaltyValue_);
        creator = msg.sender;
    }

    uint256 public totalSupply;

    address public creator;

    /**
     * @dev OS Operator filtering
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev OS Operator filtering
     */
    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
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
    function mintWithCreator(address to, uint256 tokenId) public onlyMinter {
        require(to != address(0), "mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        totalSupply += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), creator, tokenId);
        emit Transfer(creator, to, tokenId);
    }

    /**
     * @dev Creates a token with `id`, and assigns them to `to`.
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
        uint256[] memory tokenIds
    ) public onlyMinter {
        require(tokenIds.length == to.length, "Arrays length mismatch");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            mintWithCreator(to[i], tokenIds[i]);
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

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Checks for supported interface.
     *
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC2981Base) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Sets royalties for `tokenId` and `tokenRecipient` with royalty value `royaltyValue`.
     *
     */
    function setRoyalties(
        address royaltyRecipient,
        uint256 royaltyValue
    ) public onlyOwner {
        _setTokenRoyalty(royaltyRecipient, royaltyValue);
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
}