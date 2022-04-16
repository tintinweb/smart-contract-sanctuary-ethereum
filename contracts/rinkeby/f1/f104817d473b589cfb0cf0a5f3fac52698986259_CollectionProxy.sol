// SPDX-License-Identifier: MIT

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.5.16;

import {NonReentrant} from './NonReentrant.sol';

import {IGovernedProxy} from './IGovernedProxy.sol';
import {IERC721Manager} from './IERC721Manager.sol';
import {ICollectionProxy} from './ICollectionProxy.sol';

/**
 * SC-9: This contract has no chance of being updated. It must be stupid simple.
 *
 * If another upgrade logic is required in the future - it can be done as proxy stage II.
 */
contract CollectionProxy is NonReentrant, ICollectionProxy {

    address public collectionManagerProxy;

    modifier senderOrigin {
        // Internal calls are expected to use implementation directly.
        // That's due to use of call() instead of delegatecall() on purpose.
        // solium-disable-next-line security/no-tx-origin
        require(
            tx.origin == msg.sender,
            'CollectionProxy::senderOrigin: FORBIDDEN, not a direct call'
        );
        _;
    }

    function collectionManager() private view returns(address _collectionManager) {
        _collectionManager = address(IGovernedProxy(address(uint160(collectionManagerProxy))).implementation());
    }

    modifier requireManager {
        require(msg.sender == collectionManager(), 'CollectionProxy::requireManager: FORBIDDEN, not CollectionManager');
        _;
    }

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    constructor(address _collectionManagerProxy) public {
        collectionManagerProxy = _collectionManagerProxy;
    }

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    function emitTransfer(address from, address to, uint256 tokenId)
        external
        requireManager
    {
       emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    function emitApproval(address owner, address approved, uint256 tokenId)
        external
        requireManager
    {
       emit Approval(owner, approved, tokenId);
    }

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    function emitApprovalForAll(address owner, address operator, bool approved)
        external
        requireManager
    {
       emit ApprovalForAll(owner, operator,approved);
    }

    /// @param to The address that the tokens are minted to
    /// @param numberOfTokens The number of tokens
    function safeMint(address to, uint numberOfTokens)
        external
        payable
    {
        IERC721Manager(address(uint160(address(collectionManager())))).safeMint.value(msg.value)(
	        address(this),
	        msg.sender,
	        to,
	        numberOfTokens
	    );
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external {
        IERC721Manager(address(uint160(address(collectionManager())))).burn(address(this), msg.sender, tokenId);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) external {
        IERC721Manager(address(uint160(address(collectionManager())))).approve(address(this), msg.sender, to, tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external {
        IERC721Manager(address(uint160(address(collectionManager())))).setApprovalForAll(
            address(this),
            msg.sender,
            operator,
            approved
        );
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        IERC721Manager(address(uint160(address(collectionManager())))).transferFrom(
            address(this),
            msg.sender,
            from,
            to,
            tokenId
        );
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata _data
    ) external {
        IERC721Manager(address(uint160(address(collectionManager())))).safeTransferFrom(
            address(this),
            msg.sender,
            from,
            to,
            tokenId,
            _data
        );
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        IERC721Manager(address(uint160(address(collectionManager())))).safeTransferFrom(
            address(this),
            msg.sender,
            from,
            to,
            tokenId,
            ''
        );
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return IERC721Manager(collectionManager()).royaltyInfo(address(this), tokenId, salePrice);
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return IERC721Manager(collectionManager()).ownerOf(address(this), tokenId);
    }

    function balanceOf(address user) external view returns (uint256) {
        return IERC721Manager(collectionManager()).balanceOf(address(this), user);
    }

    function getApproved(uint256 tokenId) external view returns (address) {
       return IERC721Manager(collectionManager()).getApproved(address(this), tokenId);
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
       return IERC721Manager(collectionManager()).isApprovedForAll(address(this), owner, operator);
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
       return IERC721Manager(collectionManager()).tokenURI(address(this), tokenId);
    }

    function name() external view returns (string memory) {
       return IERC721Manager(collectionManager()).name(address(this));
    }

    function symbol() external view returns (string memory) {
       return IERC721Manager(collectionManager()).symbol(address(this));
    }

    function owner() external view returns (address) {
       return IERC721Manager(collectionManager()).owner();
    }

    // Proxy all other calls to CollectionManager.
    function ()
        external
        payable
        senderOrigin
    {
        // SECURITY: senderOrigin() modifier is mandatory

        address _collectionManager = collectionManager();

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())

            let res := call(sub(gas(), 10000), _collectionManager, callvalue(), ptr, calldatasize(), 0, 0)
            // NOTE: returndatasize should allow repeatable calls
            //       what should save one opcode.
            returndatacopy(ptr, 0, returndatasize())

            switch res
            case 0 {
                revert(ptr, returndatasize())
            }
            default {
                return(ptr, returndatasize())
            }
        }
    }
}