// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../extensions/AccessControl.sol";
import "../platform/royalties/IRoyaltiesRegistry.sol";
import "./IERC721LA.sol";
import "../libraries/LANFTUtils.sol";
import "../libraries/BitMaps/BitMaps.sol";

/**
 * @notice LiveArt ERC721 implementation contract
 * Supports multiple edtioned NFTs and gas optimized batch minting
 */
contract ERC721LA is IERC721LA, Initializable, AccessControl {
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               LIBRARIES
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    using BitMaps for BitMaps.BitMap;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               CONSTANTS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    bytes32 public constant IERC721METADATA_INTERFACE = hex"5b5e139f";
    bytes32 public constant IERC721_INTERFACE = hex"80ac58cd";
    bytes32 public constant IERC2981_INTERFACE = hex"2a55205a";
    bytes32 public constant IERC165_INTERFACE = hex"01ffc9a7";

    // Used for separating editionId and tokenNumber from the tokenId (cf. createEdition)
    uint256 public constant EDITION_TOKEN_MULTIPLIER = 10e5;
    uint256 public constant EDITION_MAX_SIZE = EDITION_TOKEN_MULTIPLIER - 1;

    address private constant burnAddress = address(0xDEAD);

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               STORAGE
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    struct Edition {
        string baseURI;
        uint32 maxSupply;
        uint32 currentSupply;
        uint32 burnedSupply;
        address createdBy;
    }

    /**
     * @dev Storage layout
     * This pattern allow us to extend current contract using DELETGATE_CALL
     * without worrying about storage slot conflicts
     */
    struct ERC721LAState {
        uint64 _editionCounter;
        string _name;
        string _symbol;
        mapping(uint256 => Edition) _editions;
        mapping(uint256 => address) _owners;
        mapping(uint256 => address) _tokenApprovals;
        mapping(address => uint256) _balances;
        mapping(address => mapping(address => bool)) _operatorApprovals;
        BitMaps.BitMap _batchHead;
        address _royaltyRegistry;
    }
    ERC721LAState private test;

    /// @dev Get storage data from dedicated slot. This avoid storage conflict during proxy upgrades
    function _getERC721LAState()
        internal
        pure
        returns (ERC721LAState storage state)
    {
        bytes32 position = keccak256("liveart.ERC721LA");
        assembly {
            state.slot := position
        }
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               INITIALIZERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /**
     * @dev Initialize function. Should be called by the factory when deploying new instances.
     * @param _collectionAdmin is the address of the default admin for this contract
     */
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _collectionAdmin,
        address _royaltyRegistry
    ) external notInitialized {
        ERC721LAState storage state = _getERC721LAState();
        state._name = _name;
        state._symbol = _symbol;
        state._royaltyRegistry = _royaltyRegistry;
        state._editionCounter = 1;
        _grantRole(COLLECTION_ADMIN_ROLE, _collectionAdmin);
        _grantRole(DEPLOYER_ROLE, _collectionAdmin);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        returns (bool)
    {
        return
            interfaceId == IERC2981_INTERFACE ||
            interfaceId == IERC721_INTERFACE ||
            interfaceId == IERC721METADATA_INTERFACE ||
            interfaceId == IERC165_INTERFACE;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                           IERC721Metadata
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function name() external view returns (string memory) {
        ERC721LAState storage state = _getERC721LAState();
        return state._name;
    }

    function symbol() external view returns (string memory) {
        ERC721LAState storage state = _getERC721LAState();
        return state._symbol;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        if (!_exists(tokenId)) {
            revert TokenNotFound();
        }

        ERC721LAState storage state = _getERC721LAState();
        (uint256 editionId, ) = parseEditionFromTokenId(tokenId);
        return state._editions[editionId].baseURI;
    }

    function totalSupply() external view returns (uint256) {
        ERC721LAState storage state = _getERC721LAState();
        uint256 _count;
        for (uint256 i = 1; i < state._editionCounter; i += 1) {
            _count += editionSupply(i);
        }
        return _count;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               EDITIONS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /**
     * @notice Creates a new Edition
     * Editions can be seen as collections within a collection.
     * The token Ids for the a given edition have the following format:
     * `[editionId][tokenNumber]`
     * eg.: The Id of the 2nd token of the 5th edition is: `5000002`
     *
     */
    function createEdition(
        string calldata _baseURI,
        uint32 _maxSupply,
        address _creator
    ) public onlyMinter returns (uint256) {
        if (_maxSupply >= EDITION_MAX_SIZE) {
            revert MaxSupplyError();
        }

        ERC721LAState storage state = _getERC721LAState();
        state._editions[state._editionCounter] = Edition({
            baseURI: _baseURI,
            maxSupply: _maxSupply,
            createdBy: _creator,
            burnedSupply: 0,
            currentSupply: 1
        });

        emit EditionCreated(
            address(this),
            _creator,
            state._editionCounter,
            _maxSupply,
            _baseURI
        );

        state._editionCounter += 1;
        return state._editionCounter - 1;
    }

    /**
     * @notice Creates a new Edition then mint all tokens from that edition
     */
    function createAndMintEdition(
        string calldata _baseURI,
        uint32 _maxSupply,
        address _creator
    ) external onlyMinter {
        uint256 editionId = createEdition(_baseURI, _maxSupply, _creator);
        silentMintEditionTokens(editionId, _maxSupply, _creator);
    }

    /**
     * @notice updates an edition
     */
    function updateEdition(uint256 editionId, string calldata _baseURI)
        external
        onlyAdmin
    {
        ERC721LAState storage state = _getERC721LAState();
        if (editionId > state._editionCounter) {
            revert InvalidEditionId();
        }

        Edition storage edition = state._editions[editionId];

        edition.baseURI = _baseURI;
        emit EditionUpdated(
            address(this),
            editionId,
            edition.maxSupply,
            _baseURI
        );
    }

    /**
     * @notice fetch edition struct data by editionId
     */
    function getEdition(uint256 _editionId)
        public
        view
        returns (Edition memory)
    {
        ERC721LAState storage state = _getERC721LAState();
        if (_editionId > state._editionCounter) {
            revert InvalidEditionId();
        }
        return state._editions[_editionId];
    }

    /**
     * @notice Returns the total number of editions
     */
    function totalEditions() external view returns (uint256 total) {
        ERC721LAState storage state = _getERC721LAState();
        total = state._editionCounter - 1;
    }

    /**
     * @notice Returns the current supply of a given edition
     */
    function editionSupply(uint256 editionId)
        public
        view
        returns (uint256 supply)
    {
        ERC721LAState storage state = _getERC721LAState();
        Edition memory edition = state._editions[editionId];
        return edition.currentSupply - edition.burnedSupply - 1; // -1 because currentSupply counter starts at 1
    }

    /**
     * @dev Given an editionId and  tokenNumber, returns tokenId in the following format:
     * `[editionId][tokenNumber]` where `tokenNumber` is between 1 and EDITION_TOKEN_MULTIPLIER - 1
     * eg.: The second token from the 5th edition would be `500002`
     *
     */
    function editionedTokenId(uint256 editionId, uint256 tokenNumber)
        public
        pure
        returns (uint256 tokenId)
    {
        uint256 paddedEditionID = editionId * EDITION_TOKEN_MULTIPLIER;
        tokenId = paddedEditionID + tokenNumber;
    }

    /**
     * @dev Given a tokenId return editionId and tokenNumber.
     * eg.: 3000005 => editionId 3 and tokenNumber 5
     */
    function parseEditionFromTokenId(uint256 tokenId)
        public
        pure
        returns (uint256 editionId, uint256 tokenNumber)
    {
        // Divide first to lose the decimal. ie. 1000001 / 1000000 = 1
        editionId = tokenId / EDITION_TOKEN_MULTIPLIER;
        tokenNumber = tokenId - (editionId * EDITION_TOKEN_MULTIPLIER);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               MINTING
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function silentMintEditionTokens(
        uint256 _editionId,
        uint32 _quantity,
        address _recipient
    ) public onlyMinter {
        _silentMint(_editionId, _quantity, _recipient);
    }

    function mintEditionTokens(
        uint256 _editionId,
        uint32 _quantity,
        address _recipient
    ) public onlyMinter {
        _safeMint(_editionId, _quantity, _recipient);
    }

    /**
     * @dev Internal batch minting function
     * Does not emit events.
     * This is useful to emulate lazy minting
     */
    function _silentMint(
        uint256 _editionId,
        uint32 _quantity,
        address _recipient
    ) internal returns (uint256 firstTokenId) {
        ERC721LAState storage state = _getERC721LAState();
        Edition storage edition = state._editions[_editionId];

        uint256 tokenNumber = edition.currentSupply;

        if (_editionId > state._editionCounter) {
            revert InvalidEditionId();
        }

        if (_quantity == 0 || _recipient == address(0)) {
            revert InvalidMintData();
        }

        if (tokenNumber > edition.maxSupply) {
            revert MaxSupplyError();
        }

        firstTokenId = editionedTokenId(_editionId, tokenNumber);

        // -1 is because first tokenNumber is included
        if (tokenNumber + _quantity - 1 > edition.maxSupply) {
            revert MaxSupplyError();
        }

        edition.currentSupply += _quantity;
        state._owners[firstTokenId] = _recipient;
        state._batchHead.set(firstTokenId);
        state._balances[_recipient] += _quantity;
    }

    /**
     * @dev Internal batch minting function
     */
    function _safeMint(
        uint256 _editionId,
        uint32 _quantity,
        address _recipient
    ) internal virtual {
        uint256 firstTokenId = _silentMint(_editionId, _quantity, _recipient);

        // Emit events
        for (
            uint256 tokenId = firstTokenId;
            tokenId < firstTokenId + _quantity;
            tokenId++
        ) {
            emit Transfer(address(0), _recipient, tokenId);
            _checkOnERC721Received(address(0), _recipient, tokenId, "");
        }
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               BURNABLE
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function burn(uint256 tokenId) public {
        ERC721LAState storage state = _getERC721LAState();
        address owner = ownerOf(tokenId);

        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert TransferError();
        }

        _transfer(owner, burnAddress, tokenId);
        (uint256 editionId, ) = parseEditionFromTokenId(tokenId);

        // Update the number of tokens burned for this edition
        state._editions[editionId].burnedSupply += 1;
    }

    function isBurned(uint256 tokenId) public view returns (bool) {
        ERC721LAState storage state = _getERC721LAState();
        address owner = state._owners[tokenId];
        return owner == burnAddress;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                                   ERC721
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /// @dev See {IERC721-approve}.
    function approve(address to, uint256 tokenId) external override {
        address owner = ownerOf(tokenId);
        if (
            msg.sender == to ||
            (msg.sender != owner && !isApprovedForAll(owner, msg.sender))
        ) {
            revert NotAllowed();
        }

        _approve(to, tokenId);
    }

    /// @dev See {IERC721-transferFrom}.
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert TransferError();
        }
        _transfer(from, to, tokenId);
    }

    /// @dev See {IERC721-ownerOf}.
    function ownerOf(uint256 tokenId) public view override returns (address) {
        (address owner, ) = _ownerAndBatchHeadOf(tokenId);
        return owner;
    }

    /// @dev Returns the number of tokens in ``owner``'s account.
    function balanceOf(address owner) external view returns (uint256 balance) {
        ERC721LAState storage state = _getERC721LAState();
        balance = state._balances[owner];
    }

    /// @dev See {IERC721-getApproved}.
    function getApproved(uint256 tokenId) public view returns (address) {
        if (!_exists(tokenId)) {
            revert TokenNotFound();
        }
        ERC721LAState storage state = _getERC721LAState();
        return state._tokenApprovals[tokenId];
    }

    /// @dev See {IERC721-isApprovedForAll}.
    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool)
    {
        ERC721LAState storage state = _getERC721LAState();
        return state._operatorApprovals[owner][operator];
    }

    /// @dev See {IERC721-setApprovalForAll}.
    function setApprovalForAll(address operator, bool approved)
        external
        override
    {
        if (operator == msg.sender) {
            revert NotAllowed();
        }

        ERC721LAState storage state = _getERC721LAState();
        state._operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @dev See {IERC721-safeTransferFrom}.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /// @dev See {IERC721-safeTransferFrom}.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert NotAllowed();
        }
        _safeTransfer(from, to, tokenId, _data);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                            Royalties
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /// @dev see: EIP-2981
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount)
    {
        ERC721LAState storage state = _getERC721LAState();

        return
            IRoyaltiesRegistry(state._royaltyRegistry).royaltyInfo(
                address(this),
                _tokenId,
                _value
            );
    }

    /// @dev Supports: Manifold, ArtBlocks
    function getRoyalties(uint256 _tokenId)
        public
        view
        returns (address payable[] memory, uint256[] memory)
    {
        ERC721LAState storage state = _getERC721LAState();

        return
            IRoyaltiesRegistry(state._royaltyRegistry).getRoyalties(
                address(this),
                _tokenId
            );
    }

    /// @dev Supports:Foundation
    function getFees(uint256 _tokenId)
        external
        view
        returns (address payable[] memory, uint256[] memory)
    {
        ERC721LAState storage state = _getERC721LAState();

        return
            IRoyaltiesRegistry(state._royaltyRegistry).getFees(
                address(this),
                _tokenId
            );
    }

    /// @dev Rarible: RoyaltiesV1
    function getFeeRecipients(uint256 _tokenId)
        external
        view
        returns (address payable[] memory)
    {
        ERC721LAState storage state = _getERC721LAState();

        return
            IRoyaltiesRegistry(state._royaltyRegistry).getFeeRecipients(
                address(this),
                _tokenId
            );
    }

    /// @dev Rarible: RoyaltiesV1
    function getFeeBps(uint256 _tokenId)
        external
        view
        returns (uint256[] memory)
    {
        ERC721LAState storage state = _getERC721LAState();

        return
            IRoyaltiesRegistry(state._royaltyRegistry).getFeeBps(
                address(this),
                _tokenId
            );
    }

    /// @dev Rarible: RoyaltiesV2
    function getRaribleV2Royalties(uint256 _tokenId)
        external
        view
        returns (IRaribleV2.Part[] memory)
    {
        ERC721LAState storage state = _getERC721LAState();

        return
            IRoyaltiesRegistry(state._royaltyRegistry).getRaribleV2Royalties(
                address(this),
                _tokenId
            );
    }

    /// @dev CreatorCore - Support for KODA
    function getKODAV2RoyaltyInfo(uint256 _tokenId)
        external
        view
        returns (address payable[] memory recipients_, uint256[] memory bps)
    {
        ERC721LAState storage state = _getERC721LAState();

        return
            IRoyaltiesRegistry(state._royaltyRegistry).getKODAV2RoyaltyInfo(
                address(this),
                _tokenId
            );
    }

    /// @dev CreatorCore - Support for Zora
    function convertBidShares(uint256 _tokenId)
        external
        view
        returns (address payable[] memory recipients_, uint256[] memory bps)
    {
        ERC721LAState storage state = _getERC721LAState();

        return
            IRoyaltiesRegistry(state._royaltyRegistry).convertBidShares(
                address(this),
                _tokenId
            );
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                         INTERNAL / PUBLIC HELPERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /// @dev Returns whether `tokenId` exists.
    function _exists(uint256 tokenId) internal view returns (bool) {
        (uint256 editionId, uint256 tokenNumber) = parseEditionFromTokenId(
            tokenId
        );

        if (isBurned(tokenId)) {
            return false;
        }

        ERC721LAState storage state = _getERC721LAState();
        Edition memory edition = state._editions[editionId];
        return tokenNumber < edition.currentSupply;
    }

    /**
     * @dev Returns the index of the batch for a given token.
     * If the token was not bought in a batch tokenId == tokenIdBatchHead
     */
    function _getBatchHead(uint256 tokenId)
        internal
        view
        returns (uint256 tokenIdBatchHead)
    {
        ERC721LAState storage state = _getERC721LAState();
        (uint256 editionId, ) = parseEditionFromTokenId(tokenId);
        tokenIdBatchHead = state._batchHead.scanForward(
            tokenId,
            editionId * EDITION_TOKEN_MULTIPLIER
        );
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal {
        ERC721LAState storage state = _getERC721LAState();

        state._tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Returns the index of the batch for a given token.
     * and the batch owner address
     */
    function _ownerAndBatchHeadOf(uint256 tokenId)
        internal
        view
        returns (address owner, uint256 tokenIdBatchHead)
    {
        if (!_exists(tokenId)) {
            revert TokenNotFound();
        }

        ERC721LAState storage state = _getERC721LAState();
        tokenIdBatchHead = _getBatchHead(tokenId);
        owner = state._owners[tokenIdBatchHead];
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        if (!_exists(tokenId)) {
            revert TokenNotFound();
        }

        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        ERC721LAState storage state = _getERC721LAState();
        (address owner, uint256 tokenIdBatchHead) = _ownerAndBatchHeadOf(
            tokenId
        );

        if (owner != from || to == address(0)) {
            revert TransferError();
        }

        // remove approvals
        _approve(address(0), tokenId);

        // We check if the token after the one being transfer
        // belong to the batch, if it does, we have to update it's owner
        // while being careful to not overflow the edition ID range
        uint256 nextTokenId = tokenId + 1;
        (uint256 editionId, uint256 nextTokenNumber) = parseEditionFromTokenId(
            nextTokenId
        );
        Edition memory edition = state._editions[editionId];
        if (
            nextTokenNumber <= edition.maxSupply &&
            !state._batchHead.get(nextTokenId)
        ) {
            state._owners[nextTokenId] = from;
            state._batchHead.set(nextTokenId);
        }

        // Finaly we update the owners and balances
        state._owners[tokenId] = to;
        if (tokenId != tokenIdBatchHead) {
            state._batchHead.set(tokenId);
        }

        state._balances[to] += 1;
        state._balances[from] -= 1;

        // This emulates a mint event on first transfer from edition creator
        if (owner == edition.createdBy) {
            emit Transfer(address(0), to, tokenId);
        } else {
            emit Transfer(from, to, tokenId);
        }
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, _data);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is an EOA
     *
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (LANFTUtils.isContract(to)) {
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert NotERC721Receiver();
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Initializable.sol";

abstract contract AccessControl {
    error AccessControlNotAllowed();

    bytes32 public constant COLLECTION_ADMIN_ROLE =
        keccak256("COLLECTION_ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant DEPLOYER_ROLE = 0x00;
    struct RoleState {
        mapping(bytes32 => mapping(address => bool)) _roles;
    }

    function _getAccessControlState()
        internal
        pure
        returns (RoleState storage state)
    {
        bytes32 position = keccak256("liveart.AccessControl");
        assembly {
            state.slot := position
        }
    }

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @notice Checks that msg.sender has a specific role.
     * Reverts with a AccessControlNotAllowed.
     *
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @notice Checks that msg.sender has COLLECTION_ADMIN_ROLE
     * Reverts with a AccessControlNotAllowed.
     *
     */
    modifier onlyAdmin() {
        _checkRole(COLLECTION_ADMIN_ROLE);
        _;
    }

    /**
     * @notice Checks that msg.sender has MINTER_ROLE
     * Reverts with a AccessControlNotAllowed.
     *
     */
    modifier onlyMinter() {
        _checkRole(MINTER_ROLE);
        _;
    }

    /**
     * @notice Checks if role is assigned to account
     *
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        RoleState storage state = _getAccessControlState();
        return state._roles[role][account];
    }

    /**
     * @notice Revert with a AccessControlNotAllowed message if `msg.sender` is missing `role`.
     *
     */
    function _checkRole(bytes32 role) internal view virtual {
        if (!hasRole(role, msg.sender)) {
            revert AccessControlNotAllowed();
        }
    }

    /**
     * @notice Grants `role` to `account`.
     *
     * @dev If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account)
        public
        onlyRole(COLLECTION_ADMIN_ROLE)
    {
        _grantRole(role, account);
    }

    /**
     * @notice Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have COLLECTION_ADMIN_ROLE role.
     */
    function revokeRole(bytes32 role, address account)
        public
        onlyRole(COLLECTION_ADMIN_ROLE)
    {
        _revokeRole(role, account);
    }

    /**
     * @notice Revokes `role` from the calling account.
     *
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        if (account != msg.sender) {
            revert AccessControlNotAllowed();
        }

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal {
        RoleState storage state = _getAccessControlState();
        if (!hasRole(role, account)) {
            state._roles[role][account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal {
        RoleState storage state = _getAccessControlState();
        if (hasRole(role, account)) {
            state._roles[role][account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./specs/IRarible.sol";

/// @dev Royalty registry interface
interface IRoyaltiesRegistry is IERC165 {
    /// @dev Raised when trying to set a royalty override for a token
    error NotApproved();
    error NotOwner();

    /// @dev Raised when providing multiple royalty overrides when only one is expected
    error MultipleRoyaltyRecievers();

    /// @dev Raised when sales percentage is not between 0 and 100
    error PrimarySalePercentageOutOfRange();
    error SecondarySalePercentageOutOfRange();

    // ==============================
    //            EVENTS
    // ==============================
    event RoyaltyOverride(
        address owner,
        address tokenAddress,
        address royaltyAddress
    );

    event RoyaltyTokenOverride(
        address owner,
        address tokenAddress,
        uint256 tokenId,
        address royaltyAddress
    );

    // ==============================
    //            IERC165
    // ==============================

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        external
        view
        override
        returns (bool);

    // ==============================
    //            SECONDARY ROYALTY
    // ==============================

    /*
    @notice Called with the sale price to determine how much royalty is owed and to whom.
    @param _contractAddress - The collection address
    @param _tokenId - the NFT asset queried for royalty information
    @param _value - the sale price of the NFT asset specified by _tokenId
    @return _receiver - address of who should be sent the royalty payment
    @return _royaltyAmount - the royalty payment amount for value sale price
    */
    function royaltyInfo(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _value
    ) external view returns (address _receiver, uint256 _royaltyAmount);

    /**
     *  @dev CreatorCore - Supports Manifold, ArtBlocks
     *
     *  getRoyalties
     */
    function getRoyalties(address collectionAddress, uint256 tokenId)
        external
        view
        returns (address payable[] memory, uint256[] memory);

    /**
     *  @dev Foundation
     *
     *  getFees
     */
    function getFees(address collectionAddress, uint256 editionId)
        external
        view
        returns (address payable[] memory, uint256[] memory);

    /**
     *  @dev Rarible: RoyaltiesV1
     *
     *  getFeeBps
     */
    function getFeeBps(address collectionAddress, uint256 tokenId)
        external
        view
        returns (uint256[] memory);

    /**
     *  @dev Rarible: RoyaltiesV1
     *
     *  getFeeRecipients
     */
    function getFeeRecipients(address collectionAddress, uint256 editionId)
        external
        view
        returns (address payable[] memory);

    /**
     *  @dev Rarible: RoyaltiesV2
     *
     *  getRaribleV2Royalties
     */
    function getRaribleV2Royalties(address collectionAddress, uint256 tokenId)
        external
        view
        returns (IRaribleV2.Part[] memory);

    /**
     *  @dev CreatorCore - Support for KODA
     *
     *  getKODAV2RoyaltyInfo
     */
    function getKODAV2RoyaltyInfo(address collectionAddress, uint256 tokenId)
        external
        view
        returns (address payable[] memory recipients_, uint256[] memory bps);

    /**
     *  @dev CreatorCore - Support for Zora
     *
     *  convertBidShares
     */
    function convertBidShares(address collectionAddress, uint256 tokenId)
        external
        view
        returns (address payable[] memory recipients_, uint256[] memory bps);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @dev Interface of an ERC721LA compliant contract.
 */
interface IERC721LA {
    /**
     * Raised when trying to manipulate editions (CRUD) with invalid data
     */
    error InvalidEditionData();

    error MaxSupplyError();

    error InvalidEditionId();
    /**
     * Raised when trying to mint with invalid data
     */
    error InvalidMintData();

    /**
     * Raised when trying to transfer an NFT to a non ERC721Receiver
     */
    error NotERC721Receiver();

    /**
     * Raised trying to query a non minted token
     */
    error TokenNotFound();

    /**
     * Raised tyring transfer fail
     */
    error TransferError();

    /**
     * Raised tyring transfer fail
     */
    error NotAllowed();


    // ==============================
    //            EVENTS
    // ==============================
    event EditionCreated(
        address indexed contractAddress,
        address indexed createdBy,
        uint256 editionId,
        uint256 maxSupply,
        string baseURI
    );
    event EditionUpdated(
        address indexed contractAddress,
        uint256 editionId,
        uint256 maxSupply,
        string baseURI
    );

    // ==============================
    //            IERC165
    // ==============================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // ==============================
    //            IERC721
    // ==============================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    // function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    // ==============================
    //        IERC721LA Burnable
    // ==============================

    /*
    @notice Called with the token ID to mark the token as burned. 
    @param _tokenId - the NFT token queried for burn
    */
    function burn(uint256 tokenId) external;

    /*
    @notice Called when checking if the token is burned. 
    @param _tokenId - the NFT token queried.
    */
    function isBurned(uint256 tokenId) external view returns (bool);

    // ==============================
    //        IERC721Metadata
    // ==============================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library LANFTUtils {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BitScan.sol";
/**
 * Derived from: https://github.com/estarriolvetch/solidity-bits
 */
/**
 * @dev This Library is a modified version of Openzeppelin's BitMaps library.
 * Functions of finding the index of the closest set bit from a given index are added.
 * The indexing of each bucket is modifed to count from the MSB to the LSB instead of from the LSB to the MSB.
 * The modification of indexing makes finding the closest previous set bit more efficient in gas usage.
 */

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */

error BitMapHeadNotFound();

library BitMaps {
    using BitScan for uint256;
    uint256 private constant MASK_INDEX_ZERO = (1 << 255);
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index)
        internal
        view
        returns (bool)
    {
        uint256 bucket = index >> 8;
        uint256 mask = MASK_INDEX_ZERO >> (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = MASK_INDEX_ZERO >> (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = MASK_INDEX_ZERO >> (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }

    /**
     * @dev Find the closest index of the set bit before `index`.
     */
    function scanForward(
        BitMap storage bitmap,
        uint256 index,
        uint256 lowerBound
    ) internal view returns (uint256 matchedIndex) {
        uint256 bucket = index >> 8;
        uint256 lowerBoundBucket = lowerBound >> 8;

        // index within the bucket
        uint256 bucketIndex = (index & 0xff);

        // load a bitboard from the bitmap.
        uint256 bb = bitmap._data[bucket];

        // offset the bitboard to scan from `bucketIndex`.
        bb = bb >> (0xff ^ bucketIndex); // bb >> (255 - bucketIndex)

        if (bb > 0) {
            unchecked {
                return (bucket << 8) | (bucketIndex - bb.bitScanForward256());
            }
        } else {
            while (true) {
                // require(bucket > lowerBound, "BitMaps: The set bit before the index doesn't exist.");
                if (bucket < lowerBoundBucket) {
                    revert BitMapHeadNotFound();
                }
                unchecked {
                    bucket--;
                }
                // No offset. Always scan from the least significiant bit now.
                bb = bitmap._data[bucket];

                if (bb > 0) {
                    unchecked {
                        return (bucket << 8) | (255 - bb.bitScanForward256());
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Initializable {
    error AlreadyInitialized();

    struct InitializableState {
        bool _initialized;
    }

    function _getInitializableState() internal pure returns (InitializableState storage state) {
        bytes32 position = keccak256("liveart.Initializable");
        assembly {
            state.slot := position
        }
    }

    modifier notInitialized() {
        InitializableState storage state = _getInitializableState();
        if (state._initialized) {
            revert AlreadyInitialized();
        }
        _;
        state._initialized = true;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRaribleV1 {
    /*
     * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *
     * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
     */
    function getFeeBps(uint256 id) external view returns (uint256[] memory);

    function getFeeRecipients(uint256 id)
        external
        view
        returns (address payable[] memory);
}

interface IRaribleV2 {
    /*
     *  bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca
     */
    struct Part {
        address payable account;
        uint96 value;
    }

    function getRaribleV2Royalties(uint256 id)
        external
        view
        returns (Part[] memory);
}

// SPDX-License-Identifier: MIT
/**
   _____       ___     ___ __           ____  _ __      
  / ___/____  / (_)___/ (_) /___  __   / __ )(_) /______
  \__ \/ __ \/ / / __  / / __/ / / /  / __  / / __/ ___/
 ___/ / /_/ / / / /_/ / / /_/ /_/ /  / /_/ / / /_(__  ) 
/____/\____/_/_/\__,_/_/\__/\__, /  /_____/_/\__/____/  
                           /____/                        

- npm: https://www.npmjs.com/package/solidity-bits
- github: https://github.com/estarriolvetch/solidity-bits

 */

pragma solidity ^0.8.4;


library BitScan {
    uint256 constant private DEBRUIJN_256 = 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff;
    bytes constant private LOOKUP_TABLE_256 = hex"0001020903110a19042112290b311a3905412245134d2a550c5d32651b6d3a7506264262237d468514804e8d2b95569d0d495ea533a966b11c886eb93bc176c9071727374353637324837e9b47af86c7155181ad4fd18ed32c9096db57d59ee30e2e4a6a5f92a6be3498aae067ddb2eb1d5989b56fd7baf33ca0c2ee77e5caf7ff0810182028303840444c545c646c7425617c847f8c949c48a4a8b087b8c0c816365272829aaec650acd0d28fdad4e22d6991bd97dfdcea58b4d6f29fede4f6fe0f1f2f3f4b5b6b607b8b93a3a7b7bf357199c5abcfd9e168bcdee9b3f1ecf5fd1e3e5a7a8aa2b670c4ced8bbe8f0f4fc3d79a1c3cde7effb78cce6facbf9f8";

    /**
        @dev Isolate the least significant set bit.
     */ 
    function isolateLS1B256(uint256 bb) pure internal returns (uint256) {
        require(bb > 0);
        unchecked {
            return bb & (0 - bb);
        }
    } 

    /**
        @dev Isolate the most significant set bit.
     */ 
    function isolateMS1B256(uint256 bb) pure internal returns (uint256) {
        require(bb > 0);
        unchecked {
            bb |= bb >> 256;
            bb |= bb >> 128;
            bb |= bb >> 64;
            bb |= bb >> 32;
            bb |= bb >> 16;
            bb |= bb >> 8;
            bb |= bb >> 4;
            bb |= bb >> 2;
            bb |= bb >> 1;
            
            return (bb >> 1) + 1;
        }
    } 

    /**
        @dev Find the index of the lest significant set bit. (trailing zero count)
     */ 
    function bitScanForward256(uint256 bb) pure internal returns (uint8) {
        unchecked {
            return uint8(LOOKUP_TABLE_256[(isolateLS1B256(bb) * DEBRUIJN_256) >> 248]);
        }   
    }

    /**
        @dev Find the index of the most significant set bit.
     */ 
    function bitScanReverse256(uint256 bb) pure internal returns (uint8) {
        unchecked {
            return 255 - uint8(LOOKUP_TABLE_256[((isolateMS1B256(bb) * DEBRUIJN_256) >> 248)]);
        }   
    }

}