// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC2981PerTokenRoyalties.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

/// @custom:security-contact [email protected]
contract LondonToken is
    ERC1155,
    Ownable,
    ERC2981PerTokenRoyalties,
    DefaultOperatorFilterer
{
    constructor(
        string memory uri_,
        address minter_,
        address gatewayManager_,
        string memory contractName_
    ) ERC1155(uri_) {
        mintingManager = minter_;
        gatewayManager = gatewayManager_;
        name = contractName_;
    }

    string public name = "Verse Works v0.4.0";

    uint256 public totalSupply;

    address public mintingManager;

    address public gatewayManager;

    modifier onlyMinter() {
        require(msg.sender == mintingManager);
        _;
    }

    modifier onlyGatewayManager() {
        require(msg.sender == gatewayManager);
        _;
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    /**
     * @dev OS Operator filtering
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     * In additionit sets the royalties for `royaltyRecipient` of the value `royaltyValue`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        string memory cid,
        address royaltyRecipient,
        uint256 royaltyValue
    ) public onlyMinter {
        _mint(account, id, amount, "");
        if (royaltyValue > 0) {
            _setTokenRoyalty(id, royaltyRecipient, royaltyValue);
        }
        cids[id] = cid;
        totalSupply += amount;
    }

    /**
     * @dev Batch version of `mint`.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        string[] memory tokenCids,
        address[] memory royaltyRecipients,
        uint256[] memory royaltyValues
    ) public onlyMinter {
        require(
            ids.length == royaltyRecipients.length &&
                ids.length == royaltyValues.length,
            "ERC1155: Arrays length mismatch"
        );
        _mintBatch(to, ids, amounts, "");

        for (uint256 i; i < ids.length; i++) {
            if (royaltyValues[i] > 0) {
                _setTokenRoyalty(
                    ids[i],
                    royaltyRecipients[i],
                    royaltyValues[i]
                );
            }

            // update IPFS CID
            cids[ids[i]] = tokenCids[i];
        }

        uint256 count;
        for (uint256 i = 0; i < ids.length; i++) {
            for (uint256 j = 0; j < amounts.length; j++) {
                count += ids[i] * amounts[j];
            }
        }
        totalSupply += count;
    }

    /**
     * @dev Checks for supported interface.
     *
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     * In additionit sets the royalties for `royaltyRecipient` of the value `royaltyValue`.
     * Method emits two transfer events.
     *
     * Emits a {TransferSingle} event.
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

        balances[tokenId][to] += 1;
        totalSupply += 1;
        cids[tokenId] = cid;

        if (royaltyValue > 0) {
            _setTokenRoyalty(tokenId, royaltyRecipient, royaltyValue);
        }

        address operator = _msgSender();
        emit TransferSingle(operator, address(0), creator, tokenId, 1);
        emit TransferSingle(operator, creator, to, tokenId, 1);
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     * In additionit sets the royalties for `royaltyRecipient` of the value `royaltyValue`.
     * Method emits two transfer events.
     *
     * Emits a {TransferSingle} events for intermediate artist.
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
            "ERC1155: Arrays length mismatch"
        );

        address operator = _msgSender();

        for (uint256 i = 0; i < tokenIds.length; i++) {
            balances[tokenIds[i]][to[i]] += 1;

            // check if recipient can accept NFT
            _doSafeTransferAcceptanceCheck(
                operator,
                address(0),
                to[i],
                tokenIds[i],
                1,
                ""
            );

            // update royalties
            if (royaltyValue > 0) {
                _setTokenRoyalty(tokenIds[i], royaltyRecipient, royaltyValue);
            }

            // update IPFS CID
            cids[tokenIds[i]] = tokenCids[i];

            // emit events based on creator provided
            if (creator == address(0)) {
                emit TransferSingle(
                    operator,
                    address(0),
                    to[i],
                    tokenIds[i],
                    1
                );
            } else {
                emit TransferSingle(
                    operator,
                    address(0),
                    creator,
                    tokenIds[i],
                    1
                );
                emit TransferSingle(operator, creator, to[i], tokenIds[i], 1);
            }
        }

        // update total supply
        totalSupply += tokenIds.length;
    }

    /**
     * @dev Sets base URI for metadata.
     *
     */
    function setURI(string memory newuri) public onlyGatewayManager {
        _setURI(newuri);
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
     * @dev Sets IPFS cid metadata hash for token id `tokenId`.
     *
     */
    function setCID(uint256 tokenId, string memory cid)
        public
        onlyGatewayManager
    {
        cids[tokenId] = cid;
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
            cids[tokenIds[i]] = cids_[i];
        }
    }
}